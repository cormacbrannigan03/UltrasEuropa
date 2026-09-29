import Foundation

/// Adjusts ticket/seat chances up or down based on how the favorite club
/// is actually doing right now, on top of the fixed baseline
/// `HomeSeatRequestEngine`/`ProgressionConstants.awayTicketChance` already
/// set from prestige tier and loyalty. Winning and riding high in the
/// table makes tickets harder to get (more demand); a rough patch or a
/// low league position eases them. Neither factor alone can swing things
/// wildly — `combinedMultiplier` clamps the result to a modest range.
public enum TicketDemandEngine {
    /// How many of the club's most recent played fixtures count toward
    /// its "recent form" signal — see `formMultiplier`.
    public static let formMatchWindow = 5

    /// League-average points-per-game — the neutral point where form
    /// neither raises nor lowers demand.
    public static let neutralPointsPerGame = 1.5

    /// Recent-form points-per-game (0...3) to a demand multiplier. A team
    /// on a hot streak near 3.0 PPG sells out more (multiplier < 1, chance
    /// goes down); a team in freefall near 0 PPG has tickets going begging
    /// (multiplier > 1). Right at league-average form, the baseline chance
    /// is untouched.
    public static func formMultiplier(recentPointsPerGame: Double) -> Double {
        let clamped = min(3.0, max(0.0, recentPointsPerGame))
        return 1.15 - (clamped / 3.0) * 0.30
    }

    /// League position (1-based, 1 = top) to a demand multiplier. Top of
    /// the table sells out more; the relegation zone has more room. Falls
    /// back to no adjustment (1.0) for a one-club or empty league, where
    /// "position" is meaningless.
    public static func standingMultiplier(position: Int, leagueSize: Int) -> Double {
        guard leagueSize > 1 else { return 1.0 }
        let normalized = Double(position - 1) / Double(leagueSize - 1)
        return 0.85 + normalized * 0.30
    }

    /// The combined adjustment to apply to a base ticket/seat chance — the
    /// average of the form and standing effects, clamped to 0.8...1.2 so a
    /// hot streak or a relegation battle can meaningfully move the odds
    /// without making tickets either impossible or a certainty on their
    /// own.
    public static func combinedMultiplier(recentPointsPerGame: Double, position: Int, leagueSize: Int) -> Double {
        let combined = (
            formMultiplier(recentPointsPerGame: recentPointsPerGame)
                + standingMultiplier(position: position, leagueSize: leagueSize)
        ) / 2
        return min(1.2, max(0.8, combined))
    }

    /// Applies `multiplier` to `baseChance`, clamped to a sane 0.05...1.0
    /// probability range (never impossible, never a certainty from this
    /// alone).
    public static func adjustedChance(baseChance: Double, multiplier: Double) -> Double {
        min(1.0, max(0.05, baseChance * multiplier))
    }
}
