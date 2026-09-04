import Foundation

/// The kind of condition an `AchievementCriteria` checks. Kept as a flat,
/// JSON-friendly struct (rather than an enum with associated values) so the
/// bundled achievement/item catalogs stay easy to hand-author.
public enum CriteriaKind: String, Codable, Hashable, Sendable {
    /// Player has performed `activityType` at least `threshold` times (lifetime).
    case activityCount
    /// Player has reached `rank`.
    case reachRank
    /// Player's current streak is at least `threshold` days.
    case streakDays
    /// Player has performed at least `threshold` *distinct* activity types
    /// at least once each — used to stop players from ranking up by
    /// repeating a single action.
    case activityDiversity
}

public struct AchievementCriteria: Codable, Hashable, Sendable {
    public let kind: CriteriaKind
    public let activityType: ActivityType?
    public let rank: Rank?
    public let threshold: Int?

    public init(
        kind: CriteriaKind,
        activityType: ActivityType? = nil,
        rank: Rank? = nil,
        threshold: Int? = nil
    ) {
        self.kind = kind
        self.activityType = activityType
        self.rank = rank
        self.threshold = threshold
    }

    public static func activityCount(_ type: ActivityType, _ count: Int) -> AchievementCriteria {
        AchievementCriteria(kind: .activityCount, activityType: type, threshold: count)
    }

    public static func reachRank(_ rank: Rank) -> AchievementCriteria {
        AchievementCriteria(kind: .reachRank, rank: rank)
    }

    public static func streakDays(_ days: Int) -> AchievementCriteria {
        AchievementCriteria(kind: .streakDays, threshold: days)
    }

    public static func activityDiversity(_ distinctTypes: Int) -> AchievementCriteria {
        AchievementCriteria(kind: .activityDiversity, threshold: distinctTypes)
    }
}
