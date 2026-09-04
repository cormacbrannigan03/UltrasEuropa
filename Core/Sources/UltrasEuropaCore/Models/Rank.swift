import Foundation

/// The character rank ladder, lowest to highest. Order matters: `rawValue`
/// is used for comparisons and must stay strictly increasing.
public enum Rank: Int, Codable, CaseIterable, Comparable, Hashable, Sendable {
    case regular = 0
    case youngUltra = 1
    case ultraGroup = 2
    case leadUltra = 3
    case capo = 4

    public static func < (lhs: Rank, rhs: Rank) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public var displayName: String {
        switch self {
        case .regular: return "Regular"
        case .youngUltra: return "Young Ultra"
        case .ultraGroup: return "Ultra Group"
        case .leadUltra: return "Lead Ultra"
        case .capo: return "Capo"
        }
    }

    public var next: Rank? {
        Rank(rawValue: rawValue + 1)
    }
}
