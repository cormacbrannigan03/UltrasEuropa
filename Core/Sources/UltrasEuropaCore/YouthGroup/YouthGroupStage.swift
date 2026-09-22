import Foundation

/// How far the player's own breakaway youth group has grown — from not
/// existing yet, up to the point it rivals the main ultras group in size.
/// Driven purely by member count, see `YouthGroupEngine.stage(forMemberCount:founded:)`.
public enum YouthGroupStage: Int, CaseIterable, Codable, Hashable, Sendable {
    case notFounded = 0
    case founded = 1
    case smallFollowing = 2
    case growingCrew = 3
    case establishedRival = 4
    case empireBuilt = 5

    public var displayName: String {
        switch self {
        case .notFounded: return "Not Founded"
        case .founded: return "Just Founded"
        case .smallFollowing: return "Small Following"
        case .growingCrew: return "Growing Crew"
        case .establishedRival: return "Established Rival"
        case .empireBuilt: return "Empire Built"
        }
    }

    /// What the main ultras group has to say about the youth group at this
    /// stage — shown on the Youth Group screen so the growing tension with
    /// the club's existing ultras is always visible, not just implied.
    public var mainUltrasReaction: String {
        switch self {
        case .notFounded:
            return "You haven't started anything of your own yet."
        case .founded:
            return "The main group barely notices — a few mates standing together is nothing new."
        case .smallFollowing:
            return "A couple of senior members have started asking who you're bringing to games."
        case .growingCrew:
            return "The Capo has pulled you aside: \"You're not building a group behind our backs, are you?\" They don't like it."
        case .establishedRival:
            return "It's open hostility now — the main group sees you as a genuine rival for people's loyalty, and they're not hiding it."
        case .empireBuilt:
            return "Your group is now large enough to rival the main ultras outright. Something has to give — merge with them, or take their place."
        }
    }
}
