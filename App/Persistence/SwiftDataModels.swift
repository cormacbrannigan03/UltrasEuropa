import Foundation
import SwiftData

/// The single persisted character. All progression numbers live here as
/// plain stored properties (not the Core `CharacterStats` type directly,
/// since SwiftData `@Model` types can't be pure-Swift value types) —
/// `PersistenceMapper` converts to/from `UltrasEuropaCore.CharacterStats`
/// so the pure progression engine can operate on it.
@Model
final class CharacterEntity {
    var id: UUID
    var name: String
    var favoriteClubId: String
    /// Which of the (up to `SaveSlotStore.maxSlots`) save slots this
    /// character belongs to — see `SaveSlotStore`. Defaults to 0 only so an
    /// existing on-disk character predating this field migrates cleanly;
    /// every call to the initializer below must still pass one explicitly.
    var slotIndex: Int = 0
    /// The name the player gave their own crew at creation — the source of
    /// the chants/tifo/inventory flavor in this app, since those aren't
    /// tied to any specific real club or real ultras group.
    var crewName: String
    var createdAt: Date
    var lastActiveDate: Date

    /// The in-game "season clock" for this save — drives which matches in
    /// `SeasonScheduleGenerator`'s generated schedule count as played (see
    /// `CharacterStore.matchesForClub`/`simulateDays`). Starts at
    /// the real device date when the character is created, same as the
    /// old real-time-only behavior, but only advances when the player
    /// simulates a matchday — it doesn't track the device clock after
    /// that. Separate from `lastActiveDate`, which is real-world and drives
    /// the daily loyalty streak.
    var simulatedDate: Date = .now

    var loyalty: Int
    var knowledge: Int
    var influence: Int
    var notoriety: Int
    var totalXP: Int
    var matchesAttended: Int
    var currentStreakDays: Int

    /// Raw value of `UltrasEuropaCore.Rank`.
    var rankRawValue: Int

    /// Builds toward a guaranteed away ticket for the favorite club — see
    /// `ProgressionConstants.awayTicketChance`. Separate from `loyalty`
    /// since it's specifically about away-day standing, not general
    /// progression.
    var awayLoyaltyPoints: Int

    /// Currently equipped `ClothingItem` id per slot — `nil` means nothing
    /// equipped there yet. Can reference either a bundled starter item or
    /// one of this character's own `designedClothingItems`.
    var equippedTopId: String?
    var equippedScarfId: String?
    var equippedHatId: String?

    /// Real-money store entitlements — see `CharacterStore.grantStorePurchase`
    /// and `UltrasEuropaCore.StoreProductKind`. Each is a permanent, one-time
    /// unlock granted the moment StoreKit reports a verified purchase (or
    /// transaction restore) for the matching product.
    var purchasedAllCosmeticsUnlock: Bool = false
    var purchasedTopRank: Bool = false
    var purchasedAnyHomeSeat: Bool = false
    var purchasedUnlimitedAwayPoints: Bool = false

    /// Set when stadium security ejects the player with a ban (see
    /// `SecurityIncidentEngine`) — `nil` means no active ban. The player
    /// can't confirm attendance at any match while the season clock
    /// (`simulatedDate`) is still before this date.
    var stadiumBanUntilDate: Date?

    @Relationship(deleteRule: .cascade, inverse: \OwnedItemEntity.character)
    var ownedItems: [OwnedItemEntity] = []

    @Relationship(deleteRule: .cascade, inverse: \UnlockedAchievementEntity.character)
    var unlockedAchievements: [UnlockedAchievementEntity] = []

    @Relationship(deleteRule: .cascade, inverse: \MatchAttendanceEntity.character)
    var attendanceLog: [MatchAttendanceEntity] = []

    @Relationship(deleteRule: .cascade, inverse: \ActivityLogEntity.character)
    var activityLog: [ActivityLogEntity] = []

    @Relationship(deleteRule: .cascade, inverse: \CompletedTaskEntity.character)
    var completedTasks: [CompletedTaskEntity] = []

    @Relationship(deleteRule: .cascade, inverse: \CrewRelationshipEntity.character)
    var crewRelationships: [CrewRelationshipEntity] = []

    @Relationship(deleteRule: .cascade, inverse: \DesignedClothingItemEntity.character)
    var designedClothingItems: [DesignedClothingItemEntity] = []

    /// One row per away match the player has ever requested a ticket for —
    /// the ticket outcome is locked in the first time, so re-opening the
    /// same match can't be used to re-roll a denial into a win. See
    /// `CharacterStore.attemptAwayTicket`.
    @Relationship(deleteRule: .cascade, inverse: \AwayTicketAttemptEntity.character)
    var awayTicketAttempts: [AwayTicketAttemptEntity] = []

    init(
        id: UUID = UUID(),
        name: String,
        favoriteClubId: String,
        slotIndex: Int,
        crewName: String,
        createdAt: Date = .now,
        lastActiveDate: Date = .now,
        simulatedDate: Date = .now,
        loyalty: Int = 0,
        knowledge: Int = 0,
        influence: Int = 0,
        notoriety: Int = 0,
        totalXP: Int = 0,
        matchesAttended: Int = 0,
        currentStreakDays: Int = 0,
        rankRawValue: Int = 0,
        awayLoyaltyPoints: Int = 0
    ) {
        self.id = id
        self.name = name
        self.favoriteClubId = favoriteClubId
        self.slotIndex = slotIndex
        self.crewName = crewName
        self.createdAt = createdAt
        self.lastActiveDate = lastActiveDate
        self.simulatedDate = simulatedDate
        self.loyalty = loyalty
        self.knowledge = knowledge
        self.influence = influence
        self.notoriety = notoriety
        self.awayLoyaltyPoints = awayLoyaltyPoints
        self.totalXP = totalXP
        self.matchesAttended = matchesAttended
        self.currentStreakDays = currentStreakDays
        self.rankRawValue = rankRawValue
    }
}

/// A reference to an unlocked `InventoryItem` catalog entry — the item's
/// full definition (name, category, description) lives in the bundled
/// `inventory_catalog.json`, not here, so content can be edited freely.
@Model
final class OwnedItemEntity {
    var itemId: String
    var dateAcquired: Date
    var character: CharacterEntity?

    init(itemId: String, dateAcquired: Date = .now) {
        self.itemId = itemId
        self.dateAcquired = dateAcquired
    }
}

/// A reference to an unlocked `Achievement` catalog entry.
@Model
final class UnlockedAchievementEntity {
    var achievementId: String
    var dateUnlocked: Date
    var character: CharacterEntity?

    init(achievementId: String, dateUnlocked: Date = .now) {
        self.achievementId = achievementId
        self.dateUnlocked = dateUnlocked
    }
}

@Model
final class MatchAttendanceEntity {
    var matchId: String
    var dateAttended: Date
    var satInUltrasStand: Bool
    var didPyro: Bool
    var character: CharacterEntity?

    init(
        matchId: String,
        dateAttended: Date = .now,
        satInUltrasStand: Bool = false,
        didPyro: Bool = false
    ) {
        self.matchId = matchId
        self.dateAttended = dateAttended
        self.satInUltrasStand = satInUltrasStand
        self.didPyro = didPyro
    }
}

/// One row per activity performed. Used to compute lifetime activity
/// counts (for rank/achievement gating) and today's occurrence count for
/// an activity (for diminishing returns) — see `PersistenceMapper`.
@Model
final class ActivityLogEntity {
    /// Raw value of `UltrasEuropaCore.ActivityType`.
    var activityTypeRaw: String
    var timestamp: Date
    var xpAwarded: Int
    var character: CharacterEntity?

    init(activityTypeRaw: String, timestamp: Date = .now, xpAwarded: Int) {
        self.activityTypeRaw = activityTypeRaw
        self.timestamp = timestamp
        self.xpAwarded = xpAwarded
    }
}

/// A reference to a completed `ChallengeTask` catalog entry.
@Model
final class CompletedTaskEntity {
    var taskId: String
    var dateCompleted: Date
    var character: CharacterEntity?

    init(taskId: String, dateCompleted: Date = .now) {
        self.taskId = taskId
        self.dateCompleted = dateCompleted
    }
}

/// The player's relationship with one `CrewMember` catalog entry — the
/// member's name/bio/rank lives in the bundled `crew_members.json`, not
/// here. One row is created the first time the player interacts with that
/// member; before that, their bond score is implicitly 0 (Stranger).
@Model
final class CrewRelationshipEntity {
    var memberId: String
    var bondScore: Int
    var lastInteractionDate: Date?
    var character: CharacterEntity?

    init(memberId: String, bondScore: Int = 0, lastInteractionDate: Date? = nil) {
        self.memberId = memberId
        self.bondScore = bondScore
        self.lastInteractionDate = lastInteractionDate
    }
}

/// A clothing range item the player designed themselves after reaching
/// Capo — see `CharacterStore.launchClothingRange`. Distinct from the
/// bundled starter `ClothingItem`s, which are read-only content.
@Model
final class DesignedClothingItemEntity {
    var itemId: String
    var name: String
    /// Raw value of `UltrasEuropaCore.ClothingSlot`.
    var slotRaw: String
    var createdAt: Date
    var character: CharacterEntity?

    init(itemId: String, name: String, slotRaw: String, createdAt: Date = .now) {
        self.itemId = itemId
        self.name = name
        self.slotRaw = slotRaw
        self.createdAt = createdAt
    }
}

/// The locked-in outcome of requesting an away ticket for one match — see
/// `CharacterStore.attemptAwayTicket`. Once this exists for a `matchId`,
/// the player can't attempt again for that same match.
@Model
final class AwayTicketAttemptEntity {
    var matchId: String
    var gotTicket: Bool
    var dateAttempted: Date
    var character: CharacterEntity?

    init(matchId: String, gotTicket: Bool, dateAttempted: Date = .now) {
        self.matchId = matchId
        self.gotTicket = gotTicket
        self.dateAttempted = dateAttempted
    }
}
