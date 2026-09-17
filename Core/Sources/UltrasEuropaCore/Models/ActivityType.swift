import Foundation

/// Every discrete action the player can take that grants progression.
public enum ActivityType: String, Codable, CaseIterable, Hashable, Sendable {
    case attendMatch
    case sitInUltrasStand
    case doPyroChallenge
    case participateInChant
    case contributeToTifo
    case completeTask
    case dailyLoyaltyCheckIn
    /// Recorded automatically whenever the player interacts with a
    /// `CrewMember` (see `CrewInteractionEngine`) — deliberately excluded
    /// from `ProgressionConstants.coreDiversityActivityTypes` so it's a
    /// bonus, not a required gate, on top of the existing rank ladder.
    case socializeWithCrew
    /// Recorded when the player launches a clothing range (Capo-only, see
    /// `CharacterStore.launchClothingRange`). Also excluded from the
    /// diversity gate — same reasoning as `socializeWithCrew`.
    case launchClothingRange
}
