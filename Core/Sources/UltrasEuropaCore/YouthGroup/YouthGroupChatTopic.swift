import Foundation

/// A planning topic the player can post to their own youth group's group
/// chat (`YouthGroupChatView`) — like `ChatTopic`, there's no free-text
/// input, so "what you say" means picking one of these. Themed specifically
/// around organizing for upcoming games, which is what sets this chat apart
/// from the one-on-one `CrewChatView`.
public enum YouthGroupChatTopic: String, CaseIterable, Codable, Hashable, Sendable {
    case awayDayPlan
    case meetupTime
    case tifoPlan
    case transportPlan
    case pyroPlan

    public var displayName: String {
        switch self {
        case .awayDayPlan: return "Away Day Plan"
        case .meetupTime: return "Meetup Time"
        case .tifoPlan: return "Tifo Idea"
        case .transportPlan: return "Transport"
        case .pyroPlan: return "Pyro Plan"
        }
    }

    /// What the player posts — shown as their own chat bubble before the
    /// group's reply.
    public var promptText: String {
        switch self {
        case .awayDayPlan: return "Right, here's the plan for the away day — who's in?"
        case .meetupTime: return "What time's everyone meeting up before kickoff?"
        case .tifoPlan: return "Been thinking about a display for the next home game."
        case .transportPlan: return "Sorting transport for the next one — need a lift or got space in the car?"
        case .pyroPlan: return "Bringing something special for the next one. Keep it quiet."
        }
    }
}
