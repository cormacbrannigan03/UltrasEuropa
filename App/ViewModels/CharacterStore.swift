import Foundation
import SwiftData
import Observation
import UltrasEuropaCore

/// Summary of what a single activity (or the daily check-in) produced, so a
/// view can show a rank-up celebration or "you unlocked X" toast.
struct ActivityOutcomeSummary: Equatable {
    let xpAwarded: Int
    let previousRank: Rank
    let newRank: Rank
    let newlyUnlockedAchievements: [Achievement]
    let newlyUnlockedItems: [InventoryItem]
    /// Set when this rank-up crossed into a new `UltrasGroupMembershipStage`
    /// with the character's favorite club — e.g. "Arsenal Ultras have
    /// invited you to stand with them at home games!"
    let membershipAnnouncement: String?
    /// Set when this activity's loyalty gain crossed the threshold for a
    /// standing season ticket in the favorite club's ultras section.
    let seasonTicketAnnouncement: String?

    var didRankUp: Bool { newRank > previousRank }

    static func == (lhs: ActivityOutcomeSummary, rhs: ActivityOutcomeSummary) -> Bool {
        lhs.xpAwarded == rhs.xpAwarded
            && lhs.previousRank == rhs.previousRank
            && lhs.newRank == rhs.newRank
            && lhs.newlyUnlockedAchievements.map(\.id) == rhs.newlyUnlockedAchievements.map(\.id)
            && lhs.newlyUnlockedItems.map(\.id) == rhs.newlyUnlockedItems.map(\.id)
            && lhs.membershipAnnouncement == rhs.membershipAnnouncement
            && lhs.seasonTicketAnnouncement == rhs.seasonTicketAnnouncement
    }
}

/// A player-designed clothing range item (see `CharacterStore.launchClothingRange`).
struct DesignedClothingItemSummary: Identifiable {
    let id: String
    let name: String
    let slot: ClothingSlot
}

/// The result of one crew-member interaction: the relationship outcome plus
/// whatever the accompanying `.socializeWithCrew` activity produced (XP,
/// a rank-up, unlocks).
struct CrewInteractionResult {
    let outcome: CrewInteractionOutcome
    let newBondScore: Int
    let xpOutcome: ActivityOutcomeSummary?
}

/// The single owner of character state: creation, every progression-earning
/// action, and the read-only derived values (rank, stats, next-rank
/// progress, owned items) views bind to. Wraps SwiftData persistence around
/// the pure `UltrasEuropaCore` progression engine — this class is the only
/// place those two layers meet.
@Observable
final class CharacterStore {
    private let modelContext: ModelContext
    private let content: ContentRepository

    private(set) var character: CharacterEntity?

    /// The outcome of the most recently applied activity, for the UI to
    /// present (rank-up banner, unlock toast) and then clear.
    var lastOutcome: ActivityOutcomeSummary?

    init(modelContext: ModelContext, content: ContentRepository) {
        self.modelContext = modelContext
        self.content = content
    }

    var hasCharacter: Bool { character != nil }

    // MARK: - Save slots

    /// Loads the character belonging to `slotIndex` (see `SaveSlotStore`),
    /// or clears the active character if that slot is empty — the caller
    /// (`RootView`) then shows character creation for an empty slot.
    func loadCharacter(inSlot slotIndex: Int) {
        let all = (try? modelContext.fetch(FetchDescriptor<CharacterEntity>())) ?? []
        character = all.first { $0.slotIndex == slotIndex }
        syncTheme()
    }

    /// Returns to no active character — used when backing out to the
    /// save-slot picker (see `SaveSlotStore.clearActiveSlot`).
    func clearActiveCharacter() {
        character = nil
        Theme.resetToDefaultColors()
    }

    /// Re-themes the app's accent colors to the active character's
    /// favorite club (or back to the default if there's no character) —
    /// called any time `character` changes. See `Theme.applyClubColors`.
    private func syncTheme() {
        guard let favoriteClub else {
            Theme.resetToDefaultColors()
            return
        }
        Theme.applyClubColors(primaryHex: favoriteClub.primaryColorHex, secondaryHex: favoriteClub.secondaryColorHex)
    }

    // MARK: - Character creation

    func createCharacter(name: String, favoriteClubId: String, crewName: String, slotIndex: Int, today: Date = .now) {
        let entity = CharacterEntity(
            name: name, favoriteClubId: favoriteClubId, slotIndex: slotIndex, crewName: crewName,
            createdAt: today, lastActiveDate: today, simulatedDate: today
        )
        modelContext.insert(entity)
        character = entity
        try? modelContext.save()
        syncTheme()
        // Starts the streak at day 1 without granting a duplicate check-in
        // reward on the very first app open.
        entity.currentStreakDays = 1
        try? modelContext.save()
    }

    // MARK: - Daily loyalty streak

    /// Call once when the app becomes active. Advances (or resets) the
    /// streak and, on a new day, grants the passive daily check-in reward.
    func refreshDailyStreak(today: Date = .now, calendar: Calendar = .current) {
        guard let character else { return }
        let evaluation = StreakCalculator.evaluate(
            lastActiveDate: character.lastActiveDate,
            currentStreakDays: character.currentStreakDays,
            today: today,
            calendar: calendar
        )
        character.currentStreakDays = evaluation.newStreakDays
        character.lastActiveDate = today

        if evaluation.shouldRecordDailyCheckIn {
            apply(activity: .dailyLoyaltyCheckIn, matchId: nil, satInUltrasStand: false, didPyro: false, today: today, calendar: calendar)
        } else {
            try? modelContext.save()
        }
    }

    // MARK: - Recording activities

    @discardableResult
    func recordActivity(
        _ activity: ActivityType,
        matchId: String? = nil,
        satInUltrasStand: Bool = false,
        didPyro: Bool = false,
        today: Date = .now,
        calendar: Calendar = .current
    ) -> ActivityOutcomeSummary? {
        apply(activity: activity, matchId: matchId, satInUltrasStand: satInUltrasStand, didPyro: didPyro, today: today, calendar: calendar)
    }

    func completeTask(_ taskId: String) {
        guard let character, !isTaskCompleted(taskId) else { return }
        let completion = CompletedTaskEntity(taskId: taskId)
        completion.character = character
        modelContext.insert(completion)
        character.completedTasks.append(completion)
        recordActivity(.completeTask)
    }

    func isTaskCompleted(_ taskId: String) -> Bool {
        character?.completedTasks.contains { $0.taskId == taskId } ?? false
    }

    func hasAttended(matchId: String) -> Bool {
        character?.attendanceLog.contains { $0.matchId == matchId } ?? false
    }

    // MARK: - Crew relationships

    func bondScore(forMember memberId: String) -> Int {
        guard let character else { return 0 }
        return PersistenceMapper.bondScore(forMemberId: memberId, on: character)
    }

    func relationshipLevel(forMember memberId: String) -> RelationshipLevel {
        RelationshipLevel.level(forBond: bondScore(forMember: memberId))
    }

    /// Interacts with a crew member: resolves the outcome (which can go
    /// either way — see `CrewInteractionEngine`), persists the new bond
    /// score, and also records a `.socializeWithCrew` activity so the
    /// interaction contributes a little XP like any other activity.
    @discardableResult
    func interact(with member: CrewMember, type: CrewInteractionType, today: Date = .now) -> CrewInteractionResult? {
        guard let character else { return nil }

        let currentBond = PersistenceMapper.bondScore(forMemberId: member.id, on: character)
        var generator = SystemRandomNumberGenerator()
        let (outcome, newBond) = CrewInteractionEngine.resolve(
            interaction: type, memberName: member.name, currentBond: currentBond, using: &generator
        )

        if let relationship = character.crewRelationships.first(where: { $0.memberId == member.id }) {
            relationship.bondScore = newBond
            relationship.lastInteractionDate = today
        } else {
            let relationship = CrewRelationshipEntity(memberId: member.id, bondScore: newBond, lastInteractionDate: today)
            relationship.character = character
            modelContext.insert(relationship)
            character.crewRelationships.append(relationship)
        }

        let xpOutcome = apply(
            activity: .socializeWithCrew, matchId: nil, satInUltrasStand: false, didPyro: false,
            today: today, calendar: .current
        )
        try? modelContext.save()

        return CrewInteractionResult(outcome: outcome, newBondScore: newBond, xpOutcome: xpOutcome)
    }

    // MARK: - Derived, read-only state

    var stats: CharacterStats {
        character.map(PersistenceMapper.stats(from:)) ?? .initial
    }

    /// The purchasable "Rise to the Top" entitlement overrides the earned
    /// rank outright (it's meant to bypass the climb entirely). It doesn't
    /// touch the persisted, stat-derived rank underneath, so if that were
    /// ever revoked the character would fall back to whatever they've
    /// actually earned rather than resetting to Regular.
    var rank: Rank {
        if character?.purchasedTopRank == true { return .capo }
        return character.map(PersistenceMapper.rank(from:)) ?? .regular
    }

    var unlockedAchievementIDs: Set<String> {
        character.map(PersistenceMapper.unlockedAchievementIDs(from:)) ?? []
    }

    var lifetimeActivityCounts: [ActivityType: Int] {
        character.map(PersistenceMapper.lifetimeActivityCounts(from:)) ?? [:]
    }

    /// Real, earned unlocks plus every catalog item at once if "Unlock All
    /// Cosmetics" has been purchased — see `grantStorePurchase`.
    var ownedItemIDs: Set<String> {
        var ids = Set(character?.ownedItems.map(\.itemId) ?? [])
        if character?.purchasedAllCosmeticsUnlock == true {
            ids.formUnion(content.inventoryCatalog.map(\.id))
        }
        return ids
    }

    var unlockedAchievements: [Achievement] {
        content.achievementCatalog.filter { unlockedAchievementIDs.contains($0.id) }
    }

    var ownedItems: [InventoryItem] {
        content.inventoryCatalog.filter { ownedItemIDs.contains($0.id) }
    }

    var nextRankProgress: RankProgress? {
        RankCalculator.nextRankProgress(
            current: rank,
            stats: stats,
            activityCounts: lifetimeActivityCounts,
            unlockedAchievementIDs: unlockedAchievementIDs,
            xpMultiplier: favoriteClubXPMultiplier
        )
    }

    /// How much XP the character's favorite club's prestige demands for
    /// each rank, relative to the base thresholds (1.0 = no adjustment).
    /// A fan of a bigger, more historically dominant club needs more XP
    /// for the same rank — see `ProgressionConstants.xpMultiplier(forPrestigeTier:)`.
    var favoriteClubXPMultiplier: Double {
        guard let character, let club = content.club(id: character.favoriteClubId) else { return 1.0 }
        return ProgressionConstants.xpMultiplier(forPrestigeTier: club.prestigeTier)
    }

    var favoriteClub: Club? {
        guard let character else { return nil }
        return content.club(id: character.favoriteClubId)
    }

    /// The character's current standing with their favorite club's ultras
    /// group — derived from `rank`, see `UltrasGroupMembershipStage`.
    var ultrasGroupMembershipStage: UltrasGroupMembershipStage {
        UltrasGroupMembershipStage.forRank(rank)
    }

    // MARK: - Season simulation & match schedule

    /// The in-game "today" — starts at the real device date when the
    /// character is created, and only moves when the player simulates a
    /// matchday (see `simulateDays`). Every match schedule shown anywhere
    /// in the app is generated fresh from this, not the device clock.
    var simulatedDate: Date {
        character?.simulatedDate ?? .now
    }

    func matchesForClub(_ clubId: String) -> [Match] {
        content.matchesForClub(clubId, asOf: simulatedDate)
    }

    /// The favorite club's soonest fixture that hasn't been played yet —
    /// what the Dashboard's "Next Match" card shows, so the player always
    /// has a one-tap way into the match they're building toward without
    /// detouring through the Season Calendar first.
    var nextMatchForFavoriteClub: Match? {
        guard let favoriteClub else { return nil }
        return matchesForClub(favoriteClub.id)
            .filter { !$0.isPlayed }
            .sorted { $0.date < $1.date }
            .first
    }

    /// Advances the season clock by `days` (a week for "next matchday"),
    /// revealing more fixtures' results. Doesn't touch real-world activity
    /// pacing (streaks, daily check-ins, diminishing returns) — those still
    /// run off the device's actual date.
    func simulateDays(_ days: Int, calendar: Calendar = .current) {
        guard let character, days > 0 else { return }
        character.simulatedDate = calendar.date(byAdding: .day, value: days, to: character.simulatedDate)
            ?? character.simulatedDate
        try? modelContext.save()
    }

    /// Jumps the season clock straight to `targetDate` — used by the
    /// calendar's "Fast Forward to Next Match" and the match-day cutscene's
    /// "Fast Forward to Kickoff" prompt. A no-op if `targetDate` isn't
    /// after the current season clock.
    func simulateForward(to targetDate: Date, calendar: Calendar = .current) {
        guard let character else { return }
        let days = calendar.dateComponents([.day], from: character.simulatedDate, to: targetDate).day ?? 0
        simulateDays(days, calendar: calendar)
    }

    /// Whether tickets for `match` have gone on sale yet, as of the season
    /// clock — see `TicketSaleWindow`.
    func ticketsAreOnSale(for match: Match) -> Bool {
        TicketSaleWindow.isOnSale(matchDate: match.date, asOf: simulatedDate)
    }

    /// The date tickets for `match` go on sale.
    func ticketSaleDate(for match: Match) -> Date {
        TicketSaleWindow.saleDate(matchDate: match.date)
    }

    // MARK: - Stadium security

    /// The date an active stadium ban lifts, or `nil` if there isn't one —
    /// see `applyStadiumBan`.
    var stadiumBanUntilDate: Date? {
        character?.stadiumBanUntilDate
    }

    /// Whether the player is currently banned from attending any match —
    /// true only while the season clock is still before `stadiumBanUntilDate`.
    var isBannedFromStadium: Bool {
        guard let banUntil = stadiumBanUntilDate else { return false }
        return simulatedDate < banUntil
    }

    /// Applies a stadium ban starting from the current season clock —
    /// called by `MatchDayCutsceneView` when accumulated reaction "heat"
    /// crosses `SecurityIncidentEngine.banThreshold`.
    func applyStadiumBan(days: Int, calendar: Calendar = .current) {
        guard let character else { return }
        character.stadiumBanUntilDate = calendar.date(byAdding: .day, value: days, to: simulatedDate)
        try? modelContext.save()
    }

    // MARK: - Home season ticket & away tickets

    var homeSeasonTicketLoyaltyThreshold: Int {
        ProgressionConstants.loyaltyThresholdForSeasonTicket(prestigeTier: favoriteClub?.prestigeTier ?? 3)
    }

    var hasUltrasSeasonTicket: Bool {
        if character?.purchasedAnyHomeSeat == true { return true }
        return ProgressionConstants.hasEarnedSeasonTicket(loyalty: stats.loyalty, prestigeTier: favoriteClub?.prestigeTier ?? 3)
    }

    var awayLoyaltyPoints: Int {
        character?.awayLoyaltyPoints ?? 0
    }

    var awayTicketGuaranteedThreshold: Int {
        ProgressionConstants.awayTicketGuaranteedThreshold(forPrestigeTier: favoriteClub?.prestigeTier ?? 3)
    }

    var awayTicketChance: Double {
        if character?.purchasedUnlimitedAwayPoints == true { return 1.0 }
        return ProgressionConstants.awayTicketChance(
            awayLoyaltyPoints: awayLoyaltyPoints, prestigeTier: favoriteClub?.prestigeTier ?? 3
        )
    }

    /// The locked-in outcome of a past away-ticket request for `matchId`,
    /// or `nil` if one hasn't been requested yet. Once set, this can't
    /// change — see `attemptAwayTicket`.
    func awayTicketAttempt(forMatchId matchId: String) -> Bool? {
        character?.awayTicketAttempts.first { $0.matchId == matchId }?.gotTicket
    }

    /// Requests an away ticket for `match` (should only be called for the
    /// favorite club's away games — see `MatchDetailView`). Only resolves
    /// once per match — a match that's already been attempted returns its
    /// locked-in result instead of rolling again, so a denial can't be
    /// endlessly retried into a win. Always succeeds once "Unlimited Away
    /// Access" has been purchased. Returns `nil` if there's no character yet.
    @discardableResult
    func attemptAwayTicket(for match: Match, travelMode: TravelMode, today: Date = .now) -> Bool? {
        guard let character else { return nil }

        if let existing = awayTicketAttempt(forMatchId: match.id) {
            return existing
        }

        let gotTicket: Bool
        if character.purchasedUnlimitedAwayPoints {
            gotTicket = true
        } else {
            var generator = SystemRandomNumberGenerator()
            let outcome = AwayTicketAllocationEngine.resolve(
                currentAwayLoyaltyPoints: character.awayLoyaltyPoints,
                prestigeTier: favoriteClub?.prestigeTier ?? 3,
                using: &generator
            )

            var newAwayLoyaltyPoints = outcome.newAwayLoyaltyPoints
            if travelMode == .bus {
                newAwayLoyaltyPoints += ProgressionConstants.busTravelAwayLoyaltyBonus
            }
            character.awayLoyaltyPoints = newAwayLoyaltyPoints
            gotTicket = outcome.gotTicket
        }

        let attempt = AwayTicketAttemptEntity(matchId: match.id, gotTicket: gotTicket, dateAttempted: today)
        attempt.character = character
        modelContext.insert(attempt)
        character.awayTicketAttempts.append(attempt)
        try? modelContext.save()

        return gotTicket
    }

    // MARK: - Wardrobe

    func equippedItemId(for slot: ClothingSlot) -> String? {
        guard let character else { return nil }
        switch slot {
        case .top: return character.equippedTopId
        case .scarf: return character.equippedScarfId
        case .hat: return character.equippedHatId
        }
    }

    func equip(itemId: String, slot: ClothingSlot) {
        guard let character else { return }
        switch slot {
        case .top: character.equippedTopId = itemId
        case .scarf: character.equippedScarfId = itemId
        case .hat: character.equippedHatId = itemId
        }
        try? modelContext.save()
    }

    /// Only available once Capo — running your own merch line is a
    /// leadership move.
    var canLaunchClothingRange: Bool { rank == .capo }

    var designedClothingItems: [DesignedClothingItemSummary] {
        (character?.designedClothingItems ?? []).map { entity in
            DesignedClothingItemSummary(
                id: entity.itemId, name: entity.name,
                slot: ClothingSlot(rawValue: entity.slotRaw) ?? .top
            )
        }
    }

    func designedClothingItemsInSlot(_ slot: ClothingSlot) -> [DesignedClothingItemSummary] {
        designedClothingItems.filter { $0.slot == slot }
    }

    /// Launches a new clothing range item in `slot` named `name` — only
    /// once Capo. "Selling it to the group" is represented as an immediate
    /// bond-score bump for every crew member (see
    /// `ProgressionConstants.clothingRangeCrewBondBonus`), plus the usual
    /// XP/stat reward through the shared activity pipeline.
    @discardableResult
    func launchClothingRange(name: String, slot: ClothingSlot, today: Date = .now) -> ActivityOutcomeSummary? {
        guard let character, canLaunchClothingRange else { return nil }

        let itemId = "range-\(UUID().uuidString)"
        let designed = DesignedClothingItemEntity(itemId: itemId, name: name, slotRaw: slot.rawValue, createdAt: today)
        designed.character = character
        modelContext.insert(designed)
        character.designedClothingItems.append(designed)

        let bondCap = CrewInteractionConstants.bondRange.upperBound
        for member in content.crewMembers {
            if let relationship = character.crewRelationships.first(where: { $0.memberId == member.id }) {
                relationship.bondScore = min(bondCap, relationship.bondScore + ProgressionConstants.clothingRangeCrewBondBonus)
            } else {
                let relationship = CrewRelationshipEntity(
                    memberId: member.id,
                    bondScore: min(bondCap, ProgressionConstants.clothingRangeCrewBondBonus),
                    lastInteractionDate: today
                )
                relationship.character = character
                modelContext.insert(relationship)
                character.crewRelationships.append(relationship)
            }
        }

        let outcome = apply(
            activity: .launchClothingRange, matchId: nil, satInUltrasStand: false, didPyro: false,
            today: today, calendar: .current
        )
        try? modelContext.save()
        return outcome
    }

    // MARK: - Store

    /// Whether `kind`'s entitlement has already been purchased (and so
    /// should show as "Owned" rather than a buy button — every store
    /// product here is a permanent, non-consumable unlock).
    func hasPurchased(_ kind: StoreProductKind) -> Bool {
        guard let character else { return false }
        switch kind {
        case .unlockAllCosmetics: return character.purchasedAllCosmeticsUnlock
        case .riseToTop: return character.purchasedTopRank
        case .anyHomeSeat: return character.purchasedAnyHomeSeat
        case .unlimitedAwayPoints: return character.purchasedUnlimitedAwayPoints
        }
    }

    /// Applies the entitlement for a StoreKit-verified purchase of `kind`.
    /// Called only after `PurchaseManager` has confirmed a verified
    /// transaction (a real purchase, restore, or Ask to Buy approval) —
    /// this method itself does no payment processing, it just flips the
    /// persisted flag the rest of `CharacterStore` already reads.
    func grantStorePurchase(_ kind: StoreProductKind) {
        guard let character else { return }
        switch kind {
        case .unlockAllCosmetics: character.purchasedAllCosmeticsUnlock = true
        case .riseToTop: character.purchasedTopRank = true
        case .anyHomeSeat: character.purchasedAnyHomeSeat = true
        case .unlimitedAwayPoints: character.purchasedUnlimitedAwayPoints = true
        }
        try? modelContext.save()
    }

    // MARK: - Private

    @discardableResult
    private func apply(
        activity: ActivityType,
        matchId: String?,
        satInUltrasStand: Bool,
        didPyro: Bool,
        today: Date,
        calendar: Calendar
    ) -> ActivityOutcomeSummary? {
        guard let character else { return nil }

        let statsBefore = PersistenceMapper.stats(from: character)
        let countsBefore = PersistenceMapper.lifetimeActivityCounts(from: character)
        let unlockedBefore = PersistenceMapper.unlockedAchievementIDs(from: character)
        let occurrenceIndex = PersistenceMapper.todayOccurrenceIndex(
            for: activity, on: character, today: today, calendar: calendar
        )

        let outcome = ProgressionEngine.apply(
            activity: activity,
            occurrenceIndexToday: occurrenceIndex,
            currentStats: statsBefore,
            activityCounts: countsBefore,
            unlockedAchievementIDs: unlockedBefore,
            xpMultiplier: favoriteClubXPMultiplier
        )

        PersistenceMapper.apply(outcome.updatedStats, to: character)
        PersistenceMapper.setRank(outcome.newRank, on: character)

        let log = ActivityLogEntity(activityTypeRaw: activity.rawValue, timestamp: today, xpAwarded: outcome.xpAwarded)
        log.character = character
        modelContext.insert(log)
        character.activityLog.append(log)

        if activity == .attendMatch, let matchId {
            let attendance = MatchAttendanceEntity(
                matchId: matchId, dateAttended: today,
                satInUltrasStand: satInUltrasStand, didPyro: didPyro
            )
            attendance.character = character
            modelContext.insert(attendance)
            character.attendanceLog.append(attendance)
        }

        let countsAfter = PersistenceMapper.lifetimeActivityCounts(from: character)

        let newlyUnlockedAchievements = AchievementEvaluator.newlyUnlocked(
            catalog: content.achievementCatalog,
            stats: outcome.updatedStats,
            activityCounts: countsAfter,
            currentRank: outcome.newRank,
            alreadyUnlockedIDs: unlockedBefore
        )
        for achievement in newlyUnlockedAchievements {
            let unlock = UnlockedAchievementEntity(achievementId: achievement.id)
            unlock.character = character
            modelContext.insert(unlock)
            character.unlockedAchievements.append(unlock)
        }

        let ownedBefore = Set(character.ownedItems.map(\.itemId))
        let newlyUnlockedItems = content.inventoryCatalog.filter { item in
            guard !ownedBefore.contains(item.id) else { return false }
            return AchievementEvaluator.isSatisfied(
                item.unlockCriteria,
                stats: outcome.updatedStats,
                activityCounts: countsAfter,
                currentRank: outcome.newRank
            )
        }
        for item in newlyUnlockedItems {
            let owned = OwnedItemEntity(itemId: item.id)
            owned.character = character
            modelContext.insert(owned)
            character.ownedItems.append(owned)
        }

        try? modelContext.save()

        var membershipAnnouncement: String?
        var seasonTicketAnnouncement: String?
        if let club = content.club(id: character.favoriteClubId) {
            if outcome.didRankUp {
                membershipAnnouncement = UltrasGroupMembershipStage.forRank(outcome.newRank)
                    .invitationAnnouncement(clubName: club.name)
            }
            let hadSeasonTicket = ProgressionConstants.hasEarnedSeasonTicket(
                loyalty: statsBefore.loyalty, prestigeTier: club.prestigeTier
            )
            let hasSeasonTicketNow = ProgressionConstants.hasEarnedSeasonTicket(
                loyalty: outcome.updatedStats.loyalty, prestigeTier: club.prestigeTier
            )
            if !hadSeasonTicket && hasSeasonTicketNow {
                seasonTicketAnnouncement = "You've earned a season ticket in the \(club.ultrasGroupName) section!"
            }
        }

        let summary = ActivityOutcomeSummary(
            xpAwarded: outcome.xpAwarded,
            previousRank: outcome.previousRank,
            newRank: outcome.newRank,
            newlyUnlockedAchievements: newlyUnlockedAchievements,
            newlyUnlockedItems: newlyUnlockedItems,
            membershipAnnouncement: membershipAnnouncement,
            seasonTicketAnnouncement: seasonTicketAnnouncement
        )
        lastOutcome = summary
        return summary
    }
}
