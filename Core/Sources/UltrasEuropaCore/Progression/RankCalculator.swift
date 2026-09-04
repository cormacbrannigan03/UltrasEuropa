import Foundation

public enum RankCalculator {

    /// The highest rank whose requirements are all satisfied. Requirements
    /// are cumulative in design (each rank's thresholds are supersets of the
    /// previous rank's), but this walks from the top down and returns the
    /// first satisfied rank so a requirement table doesn't have to be
    /// perfectly monotonic to behave correctly.
    public static func achievableRank(
        stats: CharacterStats,
        activityCounts: [ActivityType: Int],
        unlockedAchievementIDs: Set<String>
    ) -> Rank {
        let diversity = ProgressionConstants.activityDiversity(activityCounts: activityCounts)
        for requirement in ProgressionConstants.rankRequirements.sorted(by: { $0.rank > $1.rank }) {
            if requirement.isSatisfied(
                stats: stats,
                activityDiversity: diversity,
                unlockedAchievementIDs: unlockedAchievementIDs
            ) {
                return requirement.rank
            }
        }
        return .regular
    }

    /// The next rank up from `current`, and what's still missing to reach
    /// it — useful for a "progress to next rank" UI. Returns `nil` when
    /// already at the top rank.
    public static func nextRankProgress(
        current: Rank,
        stats: CharacterStats,
        activityCounts: [ActivityType: Int],
        unlockedAchievementIDs: Set<String>
    ) -> RankProgress? {
        guard let next = current.next,
              let requirement = ProgressionConstants.rankRequirements.first(where: { $0.rank == next })
        else { return nil }

        let diversity = ProgressionConstants.activityDiversity(activityCounts: activityCounts)
        let missingAchievements = requirement.requiredAchievementIDs.subtracting(unlockedAchievementIDs)

        return RankProgress(
            rank: next,
            xpProgress: min(stats.totalXP, requirement.minimumXP),
            xpNeeded: requirement.minimumXP,
            matchesAttendedProgress: min(stats.matchesAttended, requirement.minimumMatchesAttended),
            matchesAttendedNeeded: requirement.minimumMatchesAttended,
            activityDiversityProgress: min(diversity, requirement.minimumActivityDiversity),
            activityDiversityNeeded: requirement.minimumActivityDiversity,
            streakProgress: min(stats.currentStreakDays, requirement.minimumStreakDays),
            streakNeeded: requirement.minimumStreakDays,
            missingAchievementIDs: missingAchievements
        )
    }
}

public struct RankProgress: Sendable {
    public let rank: Rank
    public let xpProgress: Int
    public let xpNeeded: Int
    public let matchesAttendedProgress: Int
    public let matchesAttendedNeeded: Int
    public let activityDiversityProgress: Int
    public let activityDiversityNeeded: Int
    public let streakProgress: Int
    public let streakNeeded: Int
    public let missingAchievementIDs: Set<String>

    public var isFullySatisfiedExceptAchievements: Bool {
        xpProgress >= xpNeeded
            && matchesAttendedProgress >= matchesAttendedNeeded
            && activityDiversityProgress >= activityDiversityNeeded
            && streakProgress >= streakNeeded
    }
}
