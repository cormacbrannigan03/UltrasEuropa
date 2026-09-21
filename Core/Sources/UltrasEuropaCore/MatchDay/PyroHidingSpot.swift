import Foundation

/// Where a player might hide pyro before the pre-match security search
/// (see `SecurityCheckEngine`) — each spot carries a different chance of
/// actually getting it past a pat-down.
public enum PyroHidingSpot: String, CaseIterable, Codable, Hashable, Sendable {
    case insideJacket
    case rolledInScarf
    case tapedToLeg
    case insideSock

    public var displayName: String {
        switch self {
        case .insideJacket: return "Inside your jacket lining"
        case .rolledInScarf: return "Rolled up inside your scarf"
        case .tapedToLeg: return "Taped to your leg"
        case .insideSock: return "Down your sock"
        }
    }

    /// Chance of getting through the search with pyro hidden this way.
    public var searchSuccessChance: Double {
        switch self {
        case .insideJacket: return 0.55
        case .rolledInScarf: return 0.7
        case .tapedToLeg: return 0.8
        case .insideSock: return 0.6
        }
    }
}
