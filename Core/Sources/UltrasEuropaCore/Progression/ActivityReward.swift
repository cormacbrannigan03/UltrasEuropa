import Foundation

/// The base XP + stat deltas a single occurrence of an activity grants,
/// before any diminishing-returns adjustment.
public struct ActivityReward: Sendable {
    public let xp: Int
    public let loyalty: Int
    public let knowledge: Int
    public let influence: Int
    public let notoriety: Int

    public init(xp: Int, loyalty: Int = 0, knowledge: Int = 0, influence: Int = 0, notoriety: Int = 0) {
        self.xp = xp
        self.loyalty = loyalty
        self.knowledge = knowledge
        self.influence = influence
        self.notoriety = notoriety
    }
}
