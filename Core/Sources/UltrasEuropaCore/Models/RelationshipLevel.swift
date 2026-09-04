import Foundation

/// A human-readable label for a bond score. Bond scores run -100 (worst)
/// to 100 (best); a fresh relationship starts at 0.
public enum RelationshipLevel: Int, CaseIterable, Sendable {
    case rival
    case cold
    case stranger
    case acquaintance
    case friend
    case closeFriend
    case bondedForLife

    public var displayName: String {
        switch self {
        case .rival: return "Rival"
        case .cold: return "Cold"
        case .stranger: return "Stranger"
        case .acquaintance: return "Acquaintance"
        case .friend: return "Friend"
        case .closeFriend: return "Close Friend"
        case .bondedForLife: return "Bonded for Life"
        }
    }

    public static func level(forBond bond: Int) -> RelationshipLevel {
        switch bond {
        case ..<(-40): return .rival
        case -40..<0: return .cold
        case 0..<20: return .stranger
        case 20..<40: return .acquaintance
        case 40..<60: return .friend
        case 60..<85: return .closeFriend
        default: return .bondedForLife
        }
    }
}
