import Foundation

/// The ways the player can interact with a `CrewMember`. Each carries its
/// own risk/reward — see `CrewInteractionConstants`.
public enum CrewInteractionType: String, Codable, CaseIterable, Hashable, Sendable {
    case chat
    case inviteToMatch
    case shareAChant
    case standUpForThem
    case teaseThem

    public var displayName: String {
        switch self {
        case .chat: return "Chat"
        case .inviteToMatch: return "Invite to a Match"
        case .shareAChant: return "Share a Chant"
        case .standUpForThem: return "Stand Up for Them"
        case .teaseThem: return "Tease Them"
        }
    }
}
