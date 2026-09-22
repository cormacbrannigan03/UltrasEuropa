import Foundation

/// Founding and growing the player's own breakaway youth group — a slow,
/// deliberately difficult alternative path alongside the main ultras
/// group. Recruiting gets harder the bigger the group already is, since
/// early recruits are friends willing to give it a go, but every member
/// after that has to be poached from an already-established following.
public enum YouthGroupEngine {
    /// Minimum member count for each stage past `.notFounded` (which is
    /// reached the moment the group is founded, before any recruiting).
    public static let memberThresholds: [YouthGroupStage: Int] = [
        .founded: 1,
        .smallFollowing: 5,
        .growingCrew: 15,
        .establishedRival: 30,
        .empireBuilt: 50,
    ]

    /// Member count needed to unlock the merge/takeover choice.
    public static let takeoverThreshold = 50

    public static func stage(forMemberCount count: Int, founded: Bool) -> YouthGroupStage {
        guard founded else { return .notFounded }
        var current = YouthGroupStage.founded
        for stage in YouthGroupStage.allCases {
            guard let threshold = memberThresholds[stage] else { continue }
            if count >= threshold {
                current = stage
            }
        }
        return current
    }

    /// Base chance is a real long shot (30%) even for the very first
    /// recruit, and it only gets harder from there — down to a 5% floor by
    /// the time the group is large enough to be a genuine rival. This is
    /// meant to feel like "extremely hard to grow," not just "slow."
    public static func recruitChance(currentMembers: Int) -> Double {
        max(0.05, 0.30 - Double(currentMembers) * 0.005)
    }

    public static func resolveRecruit<G: RandomNumberGenerator>(
        currentMembers: Int, using generator: inout G
    ) -> Bool {
        Double.random(in: 0..<1, using: &generator) < recruitChance(currentMembers: currentMembers)
    }
}
