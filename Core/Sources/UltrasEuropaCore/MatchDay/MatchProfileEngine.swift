import Foundation

/// Assigns every fixture a `MatchCategory`, deterministically — the same
/// match always gets the same category, and it isn't purely "biggest
/// clubs = always Category 1": a per-match seeded factor lets a smaller
/// local rivalry occasionally flare up into a Category 1 fixture too,
/// same reasoning as `MatchDayContentPlanner`'s seeded chant/tifo/goal
/// assignment.
public enum MatchProfileEngine {
    /// `homeClubPrestigeTier`/`awayClubPrestigeTier` are each 1...5 (see
    /// `Club.prestigeTier`) — their sum ranges 2...10, bumped by 0-2 from
    /// a per-match hash before bucketing into a category.
    public static func category(
        matchId: String, homeClubPrestigeTier: Int, awayClubPrestigeTier: Int
    ) -> MatchCategory {
        let combinedPrestige = homeClubPrestigeTier + awayClubPrestigeTier
        let seededBump = Int(SeasonScheduleGenerator.hashSeed("\(matchId)-profile") % 3)
        let score = combinedPrestige + seededBump

        switch score {
        case 10...: return .one
        case 6..<10: return .two
        default: return .three
        }
    }
}
