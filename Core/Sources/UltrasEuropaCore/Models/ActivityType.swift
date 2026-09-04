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
}
