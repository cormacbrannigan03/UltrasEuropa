import Foundation

/// Everything a character must satisfy simultaneously to hold `rank`.
/// Deliberately more than a raw XP number: a spread of activity types,
/// a minimum number of matches actually attended, and (for the top ranks)
/// specific achievements — so reaching the top of the ladder can't be done
/// by repeating a single cheap action.
public struct RankRequirement: Sendable {
    public let rank: Rank
    public let minimumXP: Int
    public let minimumMatchesAttended: Int
    public let minimumActivityDiversity: Int
    public let minimumStreakDays: Int
    public let requiredAchievementIDs: Set<String>

    public init(
        rank: Rank,
        minimumXP: Int,
        minimumMatchesAttended: Int = 0,
        minimumActivityDiversity: Int = 0,
        minimumStreakDays: Int = 0,
        requiredAchievementIDs: Set<String> = []
    ) {
        self.rank = rank
        self.minimumXP = minimumXP
        self.minimumMatchesAttended = minimumMatchesAttended
        self.minimumActivityDiversity = minimumActivityDiversity
        self.minimumStreakDays = minimumStreakDays
        self.requiredAchievementIDs = requiredAchievementIDs
    }

    public func isSatisfied(
        stats: CharacterStats,
        activityDiversity: Int,
        unlockedAchievementIDs: Set<String>
    ) -> Bool {
        stats.totalXP >= minimumXP
            && stats.matchesAttended >= minimumMatchesAttended
            && activityDiversity >= minimumActivityDiversity
            && stats.currentStreakDays >= minimumStreakDays
            && requiredAchievementIDs.isSubset(of: unlockedAchievementIDs)
    }
}
