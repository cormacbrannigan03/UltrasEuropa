import Foundation

/// How high-profile a fixture is, and how heavy a police presence it
/// draws — Category 1 is the biggest, most contested fixtures (heavy
/// police presence, rival firms most likely to be out), Category 3 the
/// quietest (light touch, nothing much expected). Mirrors the real
/// classification used by English football policing, without claiming to
/// be an accurate real-world source. See `MatchProfileEngine`.
public enum MatchCategory: Int, CaseIterable, Codable, Hashable, Sendable {
    case one = 1
    case two = 2
    case three = 3

    public var displayName: String {
        "Category \(rawValue)"
    }

    public var policePresenceDescription: String {
        switch self {
        case .one: return "Heavy police presence — rival firms expected."
        case .two: return "A visible but lighter police presence."
        case .three: return "Police keep a light touch — a quiet fixture."
        }
    }
}
