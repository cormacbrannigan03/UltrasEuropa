import Foundation

/// The mutable, persisted numeric state of a character. Pure value type —
/// the App layer maps this to/from its SwiftData entity.
public struct CharacterStats: Codable, Equatable, Sendable {
    public var loyalty: Int
    public var knowledge: Int
    public var influence: Int
    public var notoriety: Int
    public var totalXP: Int
    public var matchesAttended: Int
    public var currentStreakDays: Int

    public init(
        loyalty: Int = 0,
        knowledge: Int = 0,
        influence: Int = 0,
        notoriety: Int = 0,
        totalXP: Int = 0,
        matchesAttended: Int = 0,
        currentStreakDays: Int = 0
    ) {
        self.loyalty = loyalty
        self.knowledge = knowledge
        self.influence = influence
        self.notoriety = notoriety
        self.totalXP = totalXP
        self.matchesAttended = matchesAttended
        self.currentStreakDays = currentStreakDays
    }

    public static let initial = CharacterStats()
}
