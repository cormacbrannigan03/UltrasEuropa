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
    /// This single activity's contribution to each stat — lets a caller
    /// (e.g. `MatchDayCutsceneView`'s post-match stat breakdown) tally up
    /// exactly how much Loyalty/Knowledge/Influence/Notoriety came from a
    /// whole sequence of activities, not just the combined XP.
    let loyaltyDelta: Int
    let knowledgeDelta: Int
    let influenceDelta: Int
    let notorietyDelta: Int

    var didRankUp: Bool { newRank > previousRank }

    static func == (lhs: ActivityOutcomeSummary, rhs: ActivityOutcomeSummary) -> Bool {
        lhs.xpAwarded == rhs.xpAwarded
            && lhs.previousRank == rhs.previousRank
            && lhs.newRank == rhs.newRank
            && lhs.newlyUnlockedAchievements.map(\.id) == rhs.newlyUnlockedAchievements.map(\.id)
            && lhs.newlyUnlockedItems.map(\.id) == rhs.newlyUnlockedItems.map(\.id)
            && lhs.membershipAnnouncement == rhs.membershipAnnouncement
            && lhs.seasonTicketAnnouncement == rhs.seasonTicketAnnouncement
            && lhs.loyaltyDelta == rhs.loyaltyDelta
            && lhs.knowledgeDelta == rhs.knowledgeDelta
            && lhs.influenceDelta == rhs.influenceDelta
            && lhs.notorietyDelta == rhs.notorietyDelta
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

/// The result of one pre-match confrontation attempt: the resolved
/// outcome (got away, or a police-issued ban) plus whatever the
/// accompanying activity produced (XP, a rank-up, unlocks).
struct UltraViolenceAttemptResult {
    let outcome: UltraViolenceOutcome
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
            interaction: type, memberName: member.name, memberRank: member.rank, playerRank: rank,
            currentBond: currentBond, using: &generator
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
        rollForYouthGroupJoinRequest(overDays: days, character: character)
        try? modelContext.save()
    }

    /// Rolls once per simulated day for an unprompted youth-group join
    /// request to appear (see `YouthGroupEngine.joinRequestChance`),
    /// stopping at the first hit — only ever one pending request at a time.
    /// Only possible once the group has grown past its founding member
    /// ("if the group grows"), and never while a merge/takeover outcome has
    /// already resolved the youth-group story.
    private func rollForYouthGroupJoinRequest(overDays days: Int, character: CharacterEntity) {
        guard character.youthGroupFounded,
              character.youthGroupOutcomeRaw == YouthGroupOutcome.none.rawValue,
              !character.youthGroupHasPendingJoinRequest,
              YouthGroupEngine.stage(forMemberCount: character.youthGroupMemberCount, founded: true) != .founded
        else { return }

        var generator = SystemRandomNumberGenerator()
        for _ in 0..<days {
            if YouthGroupEngine.resolveJoinRequestAppears(currentMembers: character.youthGroupMemberCount, using: &generator) {
                character.youthGroupHasPendingJoinRequest = true
                break
            }
        }
    }

    /// Jumps the season clock straight to `targetDate` — used by the
    /// calendar's "Fast Forward to Next Match" and the match-day cutscene's
    /// "Fast Forward to Kickoff" prompt. A no-op if `targetDate` isn't
    /// after the current season clock.
    ///
    /// Compares calendar days (via `startOfDay`), not raw elapsed time:
    /// `simulatedDate` carries whatever time-of-day the character was
    /// created at, while every generated `Match.date` lands at midnight
    /// (see `SeasonScheduleGenerator`), so a raw
    /// `dateComponents([.day], from:to:)` between them almost always
    /// undercounts by a day — e.g. from "9 Oct, 15:45" to "10 Oct, 00:00"
    /// is under 24 hours, so `.day` comes out 0 and this silently did
    /// nothing. Normalizing both sides to the start of their calendar day
    /// first fixes that while still adding the days to the real
    /// `simulatedDate` (via `simulateDays`), so its time-of-day is kept.
    func simulateForward(to targetDate: Date, calendar: Calendar = .current) {
        guard let character else { return }
        let currentDay = calendar.startOfDay(for: character.simulatedDate)
        let targetDay = calendar.startOfDay(for: targetDate)
        let days = calendar.dateComponents([.day], from: currentDay, to: targetDay).day ?? 0
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
    /// Applied once, if at all, at the end of a match where the player
    /// barely engaged — every reaction was Mild, no supporting stance was
    /// kept up, and pyro (if brought) never got lit; see
    /// `MatchDayCutsceneView.wasLowInvolvement`. A quiet penalty rather than
    /// a routed `ActivityType`: no diminishing returns, no achievement
    /// checks, just a flat XP deduction (never below 0) representing the
    /// crew noticing. Returns the amount actually deducted.
    @discardableResult
    func applyLowInvolvementPenalty(amount: Int = 15) -> Int {
        guard let character, amount > 0 else { return 0 }
        let applied = min(amount, character.totalXP)
        character.totalXP -= applied
        try? modelContext.save()
        return applied
    }

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

    // MARK: - Home stadium section requests

    /// Every section already applied for at this match, successful or
    /// not — drives the stadium map's "already tried" state.
    func homeSeatRequests(forMatchId matchId: String) -> [(seat: SeatCategory, granted: Bool)] {
        (character?.homeSeatRequests ?? [])
            .filter { $0.matchId == matchId }
            .compactMap { entity in
                guard let seat = SeatCategory(rawValue: entity.seatRawValue) else { return nil }
                return (seat, entity.granted)
            }
    }

    /// The locked-in outcome of a past request for `seat` at this match, or
    /// `nil` if that exact section hasn't been tried yet. Once set, it
    /// can't change — see `requestHomeSeat`.
    func homeSeatRequest(forMatchId matchId: String, seat: SeatCategory) -> Bool? {
        homeSeatRequests(forMatchId: matchId).first { $0.seat == seat }?.granted
    }

    /// The section the player has actually been granted for this match, if
    /// any — there's at most one, since once a request succeeds there's no
    /// reason to try another section.
    func grantedHomeSeat(forMatchId matchId: String) -> SeatCategory? {
        homeSeatRequests(forMatchId: matchId).first { $0.granted }?.seat
    }

    /// The chance (0...1) of a request for `seat` succeeding right now —
    /// shown on the stadium map before the player commits to a section.
    func homeSeatChance(for seat: SeatCategory) -> Double {
        HomeSeatRequestEngine.chance(
            for: seat, prestigeTier: favoriteClub?.prestigeTier ?? 3, hasUltrasSeasonTicket: hasUltrasSeasonTicket
        )
    }

    /// Applies for `seat` at `match`. Only resolves once per (match, seat)
    /// pair — trying the same section again for the same match returns its
    /// locked-in result instead of rolling again, so a denial can't be
    /// endlessly retried into a win. A different, easier section can still
    /// be tried afterward. Returns `nil` if there's no character yet, or if
    /// a different section has already been granted for this match.
    @discardableResult
    func requestHomeSeat(for match: Match, seat: SeatCategory, today: Date = .now) -> Bool? {
        guard let character else { return nil }

        if let existing = homeSeatRequest(forMatchId: match.id, seat: seat) {
            return existing
        }
        guard grantedHomeSeat(forMatchId: match.id) == nil else { return nil }

        let granted: Bool
        if seat == .ultrasSection && hasUltrasSeasonTicket {
            granted = true
        } else {
            var generator = SystemRandomNumberGenerator()
            granted = HomeSeatRequestEngine.resolve(
                seat: seat, prestigeTier: favoriteClub?.prestigeTier ?? 3,
                hasUltrasSeasonTicket: hasUltrasSeasonTicket, using: &generator
            )
        }

        let request = HomeSeatRequestEntity(
            matchId: match.id, seatRawValue: seat.rawValue, granted: granted, dateRequested: today
        )
        request.character = character
        modelContext.insert(request)
        character.homeSeatRequests.append(request)
        try? modelContext.save()

        return granted
    }

    // MARK: - Youth group

    /// The player's own breakaway youth group — separate from, and
    /// eventually a rival to, the favorite club's main ultras group. See
    /// `YouthGroupEngine`.
    var youthGroupFounded: Bool { character?.youthGroupFounded ?? false }
    var youthGroupMemberCount: Int { character?.youthGroupMemberCount ?? 0 }
    var youthGroupStage: YouthGroupStage {
        YouthGroupEngine.stage(forMemberCount: youthGroupMemberCount, founded: youthGroupFounded)
    }
    var youthGroupOutcome: YouthGroupOutcome {
        character.flatMap { YouthGroupOutcome(rawValue: $0.youthGroupOutcomeRaw) } ?? .none
    }
    var youthGroupRecruitChance: Double {
        YouthGroupEngine.recruitChance(currentMembers: youthGroupMemberCount)
    }
    /// Whether the youth group has grown large enough to unlock the
    /// merge-or-takeover choice, and that choice hasn't been made yet.
    var youthGroupReadyForTakeoverChoice: Bool {
        youthGroupFounded && youthGroupOutcome == .none && youthGroupMemberCount >= YouthGroupEngine.takeoverThreshold
    }
    /// Which part of the ground the youth group bases itself in — see
    /// `setYouthGroupSection`.
    var youthGroupSection: SeatCategory {
        character.flatMap { SeatCategory(rawValue: $0.youthGroupSectionRaw) } ?? .behindTheGoal
    }
    /// Whether a young supporter is currently waiting on an answer to their
    /// unprompted request to join — see `resolveYouthGroupJoinRequest`.
    var youthGroupHasPendingJoinRequest: Bool {
        character?.youthGroupHasPendingJoinRequest ?? false
    }

    /// Changes which part of the ground the youth group bases itself in.
    /// A player preference, not a chance — always succeeds.
    func setYouthGroupSection(_ section: SeatCategory) {
        guard let character else { return }
        character.youthGroupSectionRaw = section.rawValue
        try? modelContext.save()
    }

    /// Answers the pending unprompted join request — accepting adds a
    /// member for free (no `recruitChance` roll, since this member came to
    /// the group rather than needing to be talked into it) and awards the
    /// same reward as a successful recruit; declining just clears the
    /// request. Does nothing if there's no pending request.
    @discardableResult
    func resolveYouthGroupJoinRequest(accept: Bool, today: Date = .now) -> ActivityOutcomeSummary? {
        guard let character, character.youthGroupHasPendingJoinRequest else { return nil }
        character.youthGroupHasPendingJoinRequest = false
        guard accept else {
            try? modelContext.save()
            return nil
        }
        character.youthGroupMemberCount += 1
        return apply(
            activity: .recruitYouthGroupMember, matchId: nil, satInUltrasStand: false, didPyro: false,
            today: today, calendar: .current
        )
    }

    /// Founds the player's own breakaway youth group, starting at 1 member
    /// (the player themselves). One-time — does nothing if already founded.
    @discardableResult
    func foundYouthGroup(today: Date = .now) -> ActivityOutcomeSummary? {
        guard let character, !character.youthGroupFounded else { return nil }
        character.youthGroupFounded = true
        character.youthGroupMemberCount = 1
        return apply(
            activity: .foundYouthGroup, matchId: nil, satInUltrasStand: false, didPyro: false,
            today: today, calendar: .current
        )
    }

    /// Attempts to recruit one more member — deliberately a long shot that
    /// gets harder the bigger the group already is (see
    /// `YouthGroupEngine.recruitChance`). Returns whether it succeeded, or
    /// `nil` if there's no character, the group isn't founded yet, or a
    /// merge/takeover outcome has already been chosen.
    @discardableResult
    func recruitToYouthGroup(today: Date = .now) -> Bool? {
        guard let character, character.youthGroupFounded, youthGroupOutcome == .none else { return nil }

        var generator = SystemRandomNumberGenerator()
        let recruited = YouthGroupEngine.resolveRecruit(
            currentMembers: character.youthGroupMemberCount, using: &generator
        )
        if recruited {
            character.youthGroupMemberCount += 1
        }
        apply(
            activity: .recruitYouthGroupMember, matchId: nil, satInUltrasStand: false, didPyro: false,
            today: today, calendar: .current
        )
        return recruited
    }

    /// Folds the youth group into the main ultras group — the peaceful
    /// ending. One-time; does nothing unless
    /// `youthGroupReadyForTakeoverChoice` is true.
    @discardableResult
    func mergeYouthGroupWithMainUltras(today: Date = .now) -> ActivityOutcomeSummary? {
        guard let character, youthGroupReadyForTakeoverChoice else { return nil }
        character.youthGroupOutcomeRaw = YouthGroupOutcome.merged.rawValue
        return apply(
            activity: .mergeYouthGroup, matchId: nil, satInUltrasStand: false, didPyro: false,
            today: today, calendar: .current
        )
    }

    /// Takes over the main ultras group outright — the confrontational
    /// ending. One-time; does nothing unless
    /// `youthGroupReadyForTakeoverChoice` is true.
    @discardableResult
    func takeOverMainUltrasGroup(today: Date = .now) -> ActivityOutcomeSummary? {
        guard let character, youthGroupReadyForTakeoverChoice else { return nil }
        character.youthGroupOutcomeRaw = YouthGroupOutcome.tookOver.rawValue
        return apply(
            activity: .takeOverUltrasGroup, matchId: nil, satInUltrasStand: false, didPyro: false,
            today: today, calendar: .current
        )
    }

    // MARK: - Ultra violence

    /// This fixture's `MatchCategory` — see `MatchProfileEngine`. Falls
    /// back to the average tier (3) for either club if it can't be
    /// resolved, same fallback `favoriteClubXPMultiplier` etc. already use.
    func matchCategory(for match: Match) -> MatchCategory {
        let homeTier = content.club(id: match.homeClubId)?.prestigeTier ?? 3
        let awayTier = content.club(id: match.awayClubId)?.prestigeTier ?? 3
        return MatchProfileEngine.category(
            matchId: match.id, homeClubPrestigeTier: homeTier, awayClubPrestigeTier: awayTier
        )
    }

    /// Whether the player's rank is high enough to instigate a
    /// confrontation outright, rather than just piling in on one already
    /// happening — see `UltraViolenceEngine.minimumRankToInstigate`.
    var canInstigateUltraViolence: Bool {
        rank >= UltraViolenceEngine.minimumRankToInstigate
    }

    /// The locked-in outcome of a past confrontation attempt for this
    /// match, or `nil` if one hasn't happened yet. Once set, it can't
    /// change — see `attemptUltraViolence`.
    func ultraViolenceIncident(forMatchId matchId: String) -> (role: UltraViolenceRole, policeIntervention: Bool)? {
        guard let entity = character?.ultraViolenceIncidents.first(where: { $0.matchId == matchId }),
            let role = UltraViolenceRole(rawValue: entity.roleRawValue)
        else { return nil }
        return (role, entity.policeIntervention)
    }

    /// Gets involved in a pre-match confrontation with a rival firm, as
    /// `role`. Only resolves once per match — reopening the same match
    /// returns the locked-in result instead of rolling again, same
    /// anti-exploit reasoning as away tickets and home seat requests.
    /// Returns `nil` if there's no character, this match has already been
    /// attempted, or `role` is `.instigator` without
    /// `canInstigateUltraViolence`.
    @discardableResult
    func attemptUltraViolence(role: UltraViolenceRole, for match: Match, today: Date = .now) -> UltraViolenceAttemptResult? {
        guard let character else { return nil }
        guard ultraViolenceIncident(forMatchId: match.id) == nil else { return nil }
        guard role != .instigator || canInstigateUltraViolence else { return nil }

        var generator = SystemRandomNumberGenerator()
        let outcome = UltraViolenceEngine.resolve(role: role, category: matchCategory(for: match), using: &generator)

        let policeIntervention: Bool
        if case .policeIntervention(let days) = outcome {
            policeIntervention = true
            applyStadiumBan(days: days)
        } else {
            policeIntervention = false
        }

        let incident = UltraViolenceIncidentEntity(
            matchId: match.id, roleRawValue: role.rawValue, policeIntervention: policeIntervention, dateAttempted: today
        )
        incident.character = character
        modelContext.insert(incident)
        character.ultraViolenceIncidents.append(incident)

        let activity: ActivityType = role == .instigator ? .startUltraViolence : .joinUltraViolence
        let xpOutcome = apply(
            activity: activity, matchId: nil, satInUltrasStand: false, didPyro: false,
            today: today, calendar: .current
        )

        return UltraViolenceAttemptResult(outcome: outcome, xpOutcome: xpOutcome)
    }

    // MARK: - Ultras-group friendships (other clubs)

    /// The locked-in outcome of a past friendship proposal to `clubId`, or
    /// `nil` if none has been made yet. Once set, it can't change — see
    /// `proposeClubFriendship`.
    func clubFriendshipAccepted(forClubId clubId: String) -> Bool? {
        character?.clubFriendships.first { $0.clubId == clubId }?.accepted
    }

    /// Every club the player's own ultras group has an accepted
    /// friendship with.
    var friendClubIds: Set<String> {
        Set((character?.clubFriendships ?? []).filter(\.accepted).map(\.clubId))
    }

    func isFriendClub(_ clubId: String) -> Bool {
        friendClubIds.contains(clubId)
    }

    /// The chance (0...1) of `club`'s ultras group accepting a friendship
    /// proposal right now.
    func clubFriendshipChance(with club: Club) -> Double {
        ClubFriendshipEngine.chance(playerRank: rank, sameLeague: club.leagueId == favoriteClub?.leagueId)
    }

    /// Proposes an ultras-group friendship with `club` on behalf of the
    /// player's own crew. Only resolves once per club — reopening returns
    /// the locked-in result instead of rolling again. Returns `nil` if
    /// there's no character, no favorite club yet, `club` is the favorite
    /// club itself, or a proposal has already been made to this club.
    @discardableResult
    func proposeClubFriendship(with club: Club, today: Date = .now) -> Bool? {
        guard let character, let favoriteClub, favoriteClub.id != club.id else { return nil }
        guard clubFriendshipAccepted(forClubId: club.id) == nil else { return nil }

        var generator = SystemRandomNumberGenerator()
        let accepted = ClubFriendshipEngine.resolve(
            playerRank: rank, sameLeague: club.leagueId == favoriteClub.leagueId, using: &generator
        )

        let friendship = ClubFriendshipEntity(clubId: club.id, accepted: accepted, dateProposed: today)
        friendship.character = character
        modelContext.insert(friendship)
        character.clubFriendships.append(friendship)

        apply(
            activity: .proposeClubFriendship, matchId: nil, satInUltrasStand: false, didPyro: false,
            today: today, calendar: .current
        )

        return accepted
    }

    /// Arranges a joint activity (a shared tifo, a chant exchange) with a
    /// friend club's ultras group. Returns `nil` unless `isFriendClub`.
    @discardableResult
    func collaborateWithFriendClub(_ club: Club, today: Date = .now) -> ActivityOutcomeSummary? {
        guard isFriendClub(club.id) else { return nil }
        return apply(
            activity: .collaborateWithFriendClub, matchId: nil, satInUltrasStand: false, didPyro: false,
            today: today, calendar: .current
        )
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
            seasonTicketAnnouncement: seasonTicketAnnouncement,
            loyaltyDelta: outcome.updatedStats.loyalty - statsBefore.loyalty,
            knowledgeDelta: outcome.updatedStats.knowledge - statsBefore.knowledge,
            influenceDelta: outcome.updatedStats.influence - statsBefore.influence,
            notorietyDelta: outcome.updatedStats.notoriety - statsBefore.notoriety
        )
        lastOutcome = summary
        return summary
    }
}
