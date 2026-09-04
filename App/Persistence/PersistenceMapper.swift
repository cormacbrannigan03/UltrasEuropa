import Foundation
import UltrasEuropaCore

/// Converts between the SwiftData `CharacterEntity` and the pure
/// `UltrasEuropaCore` types the progression engine operates on.
enum PersistenceMapper {

    static func stats(from entity: CharacterEntity) -> CharacterStats {
        CharacterStats(
            loyalty: entity.loyalty,
            knowledge: entity.knowledge,
            influence: entity.influence,
            notoriety: entity.notoriety,
            totalXP: entity.totalXP,
            matchesAttended: entity.matchesAttended,
            currentStreakDays: entity.currentStreakDays
        )
    }

    static func apply(_ stats: CharacterStats, to entity: CharacterEntity) {
        entity.loyalty = stats.loyalty
        entity.knowledge = stats.knowledge
        entity.influence = stats.influence
        entity.notoriety = stats.notoriety
        entity.totalXP = stats.totalXP
        entity.matchesAttended = stats.matchesAttended
        entity.currentStreakDays = stats.currentStreakDays
    }

    static func rank(from entity: CharacterEntity) -> Rank {
        Rank(rawValue: entity.rankRawValue) ?? .regular
    }

    static func setRank(_ rank: Rank, on entity: CharacterEntity) {
        entity.rankRawValue = rank.rawValue
    }

    static func lifetimeActivityCounts(from entity: CharacterEntity) -> [ActivityType: Int] {
        var counts: [ActivityType: Int] = [:]
        for log in entity.activityLog {
            guard let type = ActivityType(rawValue: log.activityTypeRaw) else { continue }
            counts[type, default: 0] += 1
        }
        return counts
    }

    static func unlockedAchievementIDs(from entity: CharacterEntity) -> Set<String> {
        Set(entity.unlockedAchievements.map(\.achievementId))
    }

    /// 1-based count of how many times `activity` has already happened
    /// today for this character, including a would-be occurrence right
    /// now — feed this straight into `ProgressionEngine.apply`.
    static func todayOccurrenceIndex(
        for activity: ActivityType,
        on entity: CharacterEntity,
        today: Date,
        calendar: Calendar = .current
    ) -> Int {
        let countSoFarToday = entity.activityLog.filter {
            $0.activityTypeRaw == activity.rawValue && calendar.isDate($0.timestamp, inSameDayAs: today)
        }.count
        return countSoFarToday + 1
    }
}
