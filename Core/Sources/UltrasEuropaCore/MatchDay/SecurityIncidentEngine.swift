import Foundation

/// What stadium security does about accumulated "heat" during a single
/// match-day live-watch — see `SecurityIncidentEngine`.
public enum SecurityOutcome: Equatable, Sendable {
    case noAction
    case warned
    case ejected
    case ejectedWithBan(days: Int)
}

/// Decides how security responds to a player's reactions over the course
/// of one match, from accumulated heat (see `ReactionSeverity.heat`). The
/// thresholds themselves stay a deterministic reference point (`outcome`),
/// so the risk is still something the player can see coming, but actual
/// gameplay resolves through `resolve(forHeat:using:)` instead — crossing
/// `ejectionThreshold` makes ejection *likely*, not guaranteed, and the
/// same goes for a ban past `banThreshold`.
public enum SecurityIncidentEngine {
    public static let warningThreshold = 30
    public static let ejectionThreshold = 55
    public static let banThreshold = 85
    public static let banDurationDays = 14

    /// The deterministic "how much trouble could this heat cause" read —
    /// used by existing tests and as a reference point. See
    /// `resolve(forHeat:using:)` for what actually happens during a match.
    public static func outcome(forHeat heat: Int) -> SecurityOutcome {
        if heat >= banThreshold {
            return .ejectedWithBan(days: banDurationDays)
        } else if heat >= ejectionThreshold {
            return .ejected
        } else if heat >= warningThreshold {
            return .warned
        }
        return .noAction
    }

    /// The chance (0...1) that heat at or above `ejectionThreshold` actually
    /// gets the player thrown out this time, rather than just drawing a
    /// warning — rises the further past the threshold they've gone, but
    /// never reaches certainty, even on a very heavy night.
    public static func ejectionChance(forHeat heat: Int) -> Double {
        guard heat >= ejectionThreshold else { return 0 }
        let over = Double(heat - ejectionThreshold)
        return min(0.85, 0.45 + over / 100)
    }

    /// The chance (0...1) that heat at or above `banThreshold` escalates an
    /// ejection into a multi-day ban, rather than just being thrown out for
    /// the day.
    public static func banChance(forHeat heat: Int) -> Double {
        guard heat >= banThreshold else { return 0 }
        let over = Double(heat - banThreshold)
        return min(0.9, 0.5 + over / 100)
    }

    /// The probabilistic outcome actual gameplay resolves against — a
    /// warning below `ejectionThreshold` still always lands (there's no
    /// upside to rolling for that), but ejection and a ban past that are
    /// each a real chance rather than a guarantee.
    public static func resolve<G: RandomNumberGenerator>(
        forHeat heat: Int, using generator: inout G
    ) -> SecurityOutcome {
        guard heat >= warningThreshold else { return .noAction }
        guard heat >= ejectionThreshold else { return .warned }
        guard Double.random(in: 0..<1, using: &generator) < ejectionChance(forHeat: heat) else { return .warned }
        guard heat >= banThreshold, Double.random(in: 0..<1, using: &generator) < banChance(forHeat: heat) else {
            return .ejected
        }
        return .ejectedWithBan(days: banDurationDays)
    }
}
