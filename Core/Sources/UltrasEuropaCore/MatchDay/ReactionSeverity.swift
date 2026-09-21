import Foundation

/// How strongly the player reacts to a moment during a live-watched match
/// (see `MatchDayCutsceneView`) — from a safe, muted response up to
/// something that's guaranteed to draw attention. Each severity is its own
/// `ActivityType` (`reactMildly`...`reactExtremely`) with its own fixed
/// reward in `ProgressionConstants.activityRewards`, and its own amount of
/// stadium-security "heat" it adds — see `SecurityIncidentEngine`.
public enum ReactionSeverity: Int, CaseIterable, Codable, Hashable, Sendable {
    case mild = 0
    case moderate = 1
    case strong = 2
    case extreme = 3

    public var displayName: String {
        switch self {
        case .mild: return "Mild"
        case .moderate: return "Moderate"
        case .strong: return "Strong"
        case .extreme: return "Extreme"
        }
    }

    /// The matching activity type — see `ActivityType.reactMildly` etc.
    public var activityType: ActivityType {
        switch self {
        case .mild: return .reactMildly
        case .moderate: return .reactModerately
        case .strong: return .reactStrongly
        case .extreme: return .reactExtremely
        }
    }

    /// How much stadium-security attention this reaction draws on its own.
    /// Accumulates with every reaction across a single match — see
    /// `SecurityIncidentEngine`.
    public var heat: Int {
        switch self {
        case .mild: return 0
        case .moderate: return 8
        case .strong: return 20
        case .extreme: return 40
        }
    }
}
