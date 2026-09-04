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
    /// The name the player gave their own crew at creation — the source of
    /// the chants/tifo/inventory flavor in this app, since those aren't
    /// tied to any specific real club or real ultras group.
    var crewName: String
    var createdAt: Date
    var lastActiveDate: Date

    var loyalty: Int
    var knowledge: Int
    var influence: Int
    var notoriety: Int
    var totalXP: Int
    var matchesAttended: Int
    var currentStreakDays: Int

    /// Raw value of `UltrasEuropaCore.Rank`.
    var rankRawValue: Int

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

    init(
        id: UUID = UUID(),
        name: String,
        favoriteClubId: String,
        crewName: String,
        createdAt: Date = .now,
        lastActiveDate: Date = .now,
        loyalty: Int = 0,
        knowledge: Int = 0,
        influence: Int = 0,
        notoriety: Int = 0,
        totalXP: Int = 0,
        matchesAttended: Int = 0,
        currentStreakDays: Int = 0,
        rankRawValue: Int = 0
    ) {
        self.id = id
        self.name = name
        self.favoriteClubId = favoriteClubId
        self.crewName = crewName
        self.createdAt = createdAt
        self.lastActiveDate = lastActiveDate
        self.loyalty = loyalty
        self.knowledge = knowledge
        self.influence = influence
        self.notoriety = notoriety
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
