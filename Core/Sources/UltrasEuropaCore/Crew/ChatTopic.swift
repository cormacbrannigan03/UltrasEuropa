import Foundation

/// A conversation topic the player can bring up with a crew member on the
/// chat screen (`CrewChatView`). There's no free-text input, so "what you
/// say" means picking one of these — each has its own line the player's
/// chat bubble shows, and its own pool of generic replies in
/// `CrewChatConstants`.
public enum ChatTopic: String, CaseIterable, Codable, Hashable, Sendable {
    case lastMatch
    case upcomingMatch
    case lifeOutsideFootball
    case theClub
    case banter
    case transferRumors
    case rivalClub
    case oldDays

    public var displayName: String {
        switch self {
        case .lastMatch: return "Last Match"
        case .upcomingMatch: return "Next Match"
        case .lifeOutsideFootball: return "How's Life"
        case .theClub: return "The Club"
        case .banter: return "Banter"
        case .transferRumors: return "Transfer Talk"
        case .rivalClub: return "Our Rivals"
        case .oldDays: return "The Old Days"
        }
    }

    /// What the player says — shown as their own chat bubble before the
    /// crew member's reply.
    public var promptText: String {
        switch self {
        case .lastMatch: return "So, what did you make of the last match?"
        case .upcomingMatch: return "You coming down for the next one?"
        case .lifeOutsideFootball: return "How's things been outside of all this?"
        case .theClub: return "What's your honest read on the club right now?"
        case .banter: return "Oi, you're all talk and no away days, you."
        case .transferRumors: return "Heard anything about who we're signing?"
        case .rivalClub: return "What's the story with our rivals these days?"
        case .oldDays: return "Remember the old days following this club?"
        }
    }
}
