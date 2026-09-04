import Foundation

public enum AchievementEvaluator {

    /// Returns the achievements from `catalog` whose criteria are now met
    /// but that aren't already in `alreadyUnlockedIDs`.
    public static func newlyUnlocked(
        catalog: [Achievement],
        stats: CharacterStats,
        activityCounts: [ActivityType: Int],
        currentRank: Rank,
        alreadyUnlockedIDs: Set<String>
    ) -> [Achievement] {
        catalog.filter { achievement in
            guard !alreadyUnlockedIDs.contains(achievement.id) else { return false }
            return isSatisfied(
                achievement.criteria,
                stats: stats,
                activityCounts: activityCounts,
                currentRank: currentRank
            )
        }
    }

    /// Evaluates a single `AchievementCriteria`. Public because
    /// `InventoryItem.unlockCriteria` shares the same shape — callers
    /// unlocking catalog items (not just achievements) reuse this instead
    /// of duplicating the switch.
    public static func isSatisfied(
        _ criteria: AchievementCriteria,
        stats: CharacterStats,
        activityCounts: [ActivityType: Int],
        currentRank: Rank
    ) -> Bool {
        switch criteria.kind {
        case .activityCount:
            guard let type = criteria.activityType, let threshold = criteria.threshold else { return false }
            return (activityCounts[type] ?? 0) >= threshold
        case .reachRank:
            guard let rank = criteria.rank else { return false }
            return currentRank >= rank
        case .streakDays:
            guard let threshold = criteria.threshold else { return false }
            return stats.currentStreakDays >= threshold
        case .activityDiversity:
            guard let threshold = criteria.threshold else { return false }
            return ProgressionConstants.activityDiversity(activityCounts: activityCounts) >= threshold
        }
    }
}
