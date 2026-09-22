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
/// of one match, purely from accumulated heat (see `ReactionSeverity.heat`)
/// — deterministic and threshold-based rather than randomized, so the risk
/// is something the player can see coming and choose to manage, not a
/// hidden dice roll.
public enum SecurityIncidentEngine {
    public static let warningThreshold = 30
    public static let ejectionThreshold = 55
    public static let banThreshold = 85
    public static let banDurationDays = 14

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
}
