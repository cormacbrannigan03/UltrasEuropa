import Foundation

/// Deterministically fabricates basic match stats (shots, shots on target,
/// possession, corners) for a fixture whose final score is already fixed —
/// same seeded-hash technique as `MatchDayContentPlanner.goalEvents`: stable
/// across launches for the same match id, and biased toward whichever side
/// scored more, without ever contradicting the real result.
public enum MatchStatsEngine {

    /// Shots each side takes before any goal-based bias, drawn from this
    /// range via a seeded hash.
    private static let baseShotsRange = 8...18
    private static let baseCornersRange = 2...9
    /// How many extra shots/corners the side that won the game gets per
    /// goal of margin, capped so a blowout doesn't look absurd.
    private static let maxGoalDiffBias = 6

    public static func generate(matchId: String, homeGoals: Int, awayGoals: Int) -> MatchStats {
        let goalDiff = homeGoals - awayGoals
        let bias = max(-maxGoalDiffBias, min(maxGoalDiffBias, goalDiff * 2))

        let homeShots = max(homeGoals, seededValue(seed: "\(matchId)-home-shots", range: baseShotsRange) + max(0, bias))
        let awayShots = max(awayGoals, seededValue(seed: "\(matchId)-away-shots", range: baseShotsRange) + max(0, -bias))

        let homeShotsOnTarget = clampShotsOnTarget(
            seededValue(seed: "\(matchId)-home-sot", range: 3...homeShots),
            shots: homeShots,
            goals: homeGoals
        )
        let awayShotsOnTarget = clampShotsOnTarget(
            seededValue(seed: "\(matchId)-away-sot", range: 3...awayShots),
            shots: awayShots,
            goals: awayGoals
        )

        let homeCorners = max(0, seededValue(seed: "\(matchId)-home-corners", range: baseCornersRange) + max(0, bias / 2))
        let awayCorners = max(0, seededValue(seed: "\(matchId)-away-corners", range: baseCornersRange) + max(0, -bias / 2))

        let possessionBase = seededValue(seed: "\(matchId)-possession", range: 30...70)
        let possessionAdjustment = bias > 0 ? 3 : (bias < 0 ? -3 : 0)
        let homePossession = min(70, max(30, possessionBase + possessionAdjustment))

        return MatchStats(
            homeShots: homeShots,
            homeShotsOnTarget: homeShotsOnTarget,
            homeCorners: homeCorners,
            homePossession: homePossession,
            awayShots: awayShots,
            awayShotsOnTarget: awayShotsOnTarget,
            awayCorners: awayCorners,
            awayPossession: 100 - homePossession
        )
    }

    /// Shots on target can never exceed total shots, and must be at least
    /// enough to cover the goals actually scored.
    private static func clampShotsOnTarget(_ value: Int, shots: Int, goals: Int) -> Int {
        min(shots, max(goals, value))
    }

    /// A stable value in `range`, seeded off `seed`. Falls back to
    /// `range.lowerBound` if the range is empty or inverted (can happen when
    /// `homeShots`/`awayShots` end up smaller than a fixed lower bound).
    private static func seededValue(seed: String, range: ClosedRange<Int>) -> Int {
        let lower = range.lowerBound
        let upper = max(lower, range.upperBound)
        guard upper > lower else { return lower }
        let hash = SeasonScheduleGenerator.hashSeed(seed)
        return lower + Int(hash % UInt64(upper - lower + 1))
    }
}
