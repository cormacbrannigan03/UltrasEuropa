import Foundation

/// Where the player sits for a home game. `ultrasSection` is only
/// selectable once `ProgressionConstants.hasEarnedSeasonTicket` is true for
/// the favorite club — everything else is always available.
public enum SeatCategory: String, CaseIterable, Hashable, Sendable {
    case mainStand
    case familySection
    case behindTheGoal
    case ultrasSection

    public var displayName: String {
        switch self {
        case .mainStand: return "Main Stand"
        case .familySection: return "Family Section"
        case .behindTheGoal: return "Behind the Goal"
        case .ultrasSection: return "Ultras Section"
        }
    }
}
