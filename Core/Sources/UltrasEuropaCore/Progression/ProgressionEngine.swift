import Foundation

/// Result of applying a single activity to a character's stats.
public struct ActivityOutcome: Sendable {
    public let updatedStats: CharacterStats
    public let xpAwarded: Int
    public let previousRank: Rank
    public let newRank: Rank

    public var didRankUp: Bool { newRank > previousRank }
}

public enum ProgressionEngine {

    /// Applies one occurrence of `activity` to `currentStats`.
    ///
    /// - Parameters:
    ///   - occurrenceIndexToday: 1-based count of how many times this exact
    ///     activity has already happened today, including this one (i.e.
    ///     pass 1 for the first time today, 2 for the second, ...). Drives
    ///     the diminishing-returns curve.
    ///   - activityCounts: lifetime counts per activity type *before* this
    ///     activity is applied — used to compute the rank before/after so
    ///     callers can detect a rank-up.
    ///   - unlockedAchievementIDs: achievement IDs already unlocked, used
    ///     for rank gating (some ranks require specific achievements).
    public static func apply(
        activity: ActivityType,
        occurrenceIndexToday: Int,
        currentStats: CharacterStats,
        activityCounts: [ActivityType: Int],
        unlockedAchievementIDs: Set<String>
    ) -> ActivityOutcome {
        let reward = ProgressionConstants.activityRewards[activity] ?? ActivityReward(xp: 0)
        let multiplier = ProgressionConstants.diminishingReturnsMultiplier(occurrenceIndexToday: occurrenceIndexToday)

        func scaled(_ base: Int) -> Int {
            Int((Double(base) * multiplier).rounded())
        }

        let xpAwarded = scaled(reward.xp)

        var updatedStats = currentStats
        updatedStats.totalXP += xpAwarded
        updatedStats.loyalty += scaled(reward.loyalty)
        updatedStats.knowledge += scaled(reward.knowledge)
        updatedStats.influence += scaled(reward.influence)
        updatedStats.notoriety += scaled(reward.notoriety)
        if activity == .attendMatch {
            updatedStats.matchesAttended += 1
        }

        var updatedActivityCounts = activityCounts
        updatedActivityCounts[activity, default: 0] += 1

        let previousRank = RankCalculator.achievableRank(
            stats: currentStats,
            activityCounts: activityCounts,
            unlockedAchievementIDs: unlockedAchievementIDs
        )
        let newRank = RankCalculator.achievableRank(
            stats: updatedStats,
            activityCounts: updatedActivityCounts,
            unlockedAchievementIDs: unlockedAchievementIDs
        )

        return ActivityOutcome(
            updatedStats: updatedStats,
            xpAwarded: xpAwarded,
            previousRank: previousRank,
            newRank: newRank
        )
    }
}
