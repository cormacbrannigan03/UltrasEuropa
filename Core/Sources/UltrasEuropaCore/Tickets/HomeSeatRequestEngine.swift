import Foundation

/// Resolves whether a request for a specific stadium section succeeds.
/// Every section has its own base chance — the Ultras Section is
/// deliberately the hardest to get into, mirroring how contested a real
/// standing/singing end is — and a fan of a bigger, more prestigious club
/// (see `Club.prestigeTier`) finds every section a little more
/// oversubscribed, not just the Ultras Section. A season-ticket holder
/// (`ProgressionConstants.hasEarnedSeasonTicket`) is always guaranteed a
/// spot in the Ultras Section instead of rolling for it.
public enum HomeSeatRequestEngine {
    /// Base chance (0...1) of a request for a section succeeding, before
    /// the favorite club's prestige tier is factored in. `behindTheGoal`
    /// shares its stand with `ultrasSection` — the same end of the ground,
    /// just the seated part of it rather than the singing terrace — so
    /// demand spills over from fans who couldn't get into the Ultras
    /// Section, making that whole end harder to get into than the Main
    /// Stand or Family Section on the other side of the pitch.
    public static let baseChance: [SeatCategory: Double] = [
        .mainStand: 0.75,
        .familySection: 0.95,
        .behindTheGoal: 0.50,
        .ultrasSection: 0.30,
    ]

    /// How much harder every section gets to secure at each `prestigeTier`
    /// — a fan of a small club (tier 1) has noticeably better odds than a
    /// fan of a global giant (tier 5).
    public static let prestigeDifficultyMultiplier: [Int: Double] = [
        1: 1.15,
        2: 1.05,
        3: 1.0,
        4: 0.85,
        5: 0.65,
    ]

    /// The chance of a request for `seat` succeeding for a fan of a club
    /// at `prestigeTier`. A season-ticket holder requesting the Ultras
    /// Section is always guaranteed a spot instead of rolling.
    public static func chance(for seat: SeatCategory, prestigeTier: Int, hasUltrasSeasonTicket: Bool) -> Double {
        if seat == .ultrasSection && hasUltrasSeasonTicket { return 1.0 }
        let base = baseChance[seat] ?? 0.75
        let multiplier = prestigeDifficultyMultiplier[prestigeTier] ?? 1.0
        return min(1.0, max(0.05, base * multiplier))
    }

    public static func resolve<G: RandomNumberGenerator>(
        seat: SeatCategory, prestigeTier: Int, hasUltrasSeasonTicket: Bool, using generator: inout G
    ) -> Bool {
        Double.random(in: 0..<1, using: &generator)
            < chance(for: seat, prestigeTier: prestigeTier, hasUltrasSeasonTicket: hasUltrasSeasonTicket)
    }
}
