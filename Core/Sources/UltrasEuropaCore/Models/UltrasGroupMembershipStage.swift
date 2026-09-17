import Foundation

/// The player's standing with their favorite club's ultras group. Derived
/// entirely from the existing `Rank` ladder — reaching Ultra Group,
/// Lead Ultra, and Capo already means "invited to sit with them at home
/// games," "invited on away trips too," and "leading the group," so this
/// reuses those thresholds directly rather than adding a second, separate
/// progression track.
public enum UltrasGroupMembershipStage: Int, CaseIterable, Sendable {
    case notNoticed
    case invitedHomeGames
    case invitedAwayGames
    case fullMember

    public var displayName: String {
        switch self {
        case .notNoticed: return "Not Noticed Yet"
        case .invitedHomeGames: return "Invited — Home Games"
        case .invitedAwayGames: return "Invited — Away Games"
        case .fullMember: return "Full Member"
        }
    }

    public var description: String {
        switch self {
        case .notNoticed:
            return "Keep building your reputation — the ultras haven't noticed you yet."
        case .invitedHomeGames:
            return "You've been invited to stand with them at home games."
        case .invitedAwayGames:
            return "You've earned a place on away trips too."
        case .fullMember:
            return "You're a full member of the group now."
        }
    }

    public static func forRank(_ rank: Rank) -> UltrasGroupMembershipStage {
        switch rank {
        case .regular, .youngUltra: return .notNoticed
        case .ultraGroup: return .invitedHomeGames
        case .leadUltra: return .invitedAwayGames
        case .capo: return .fullMember
        }
    }

    /// A one-off announcement for the moment a rank-up crosses into this
    /// stage — `nil` for `.notNoticed`, since that's the default starting
    /// point, not something worth announcing.
    public func invitationAnnouncement(clubName: String) -> String? {
        switch self {
        case .notNoticed:
            return nil
        case .invitedHomeGames:
            return "\(clubName) Ultras have invited you to stand with them at home games!"
        case .invitedAwayGames:
            return "\(clubName) Ultras want you on away trips too now!"
        case .fullMember:
            return "You're officially a full member of \(clubName) Ultras!"
        }
    }
}
