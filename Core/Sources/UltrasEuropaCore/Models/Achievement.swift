import Foundation

public struct Achievement: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let achievementDescription: String
    public let criteria: AchievementCriteria

    public init(
        id: String,
        name: String,
        achievementDescription: String,
        criteria: AchievementCriteria
    ) {
        self.id = id
        self.name = name
        self.achievementDescription = achievementDescription
        self.criteria = criteria
    }

    enum CodingKeys: String, CodingKey {
        case id, name, criteria
        case achievementDescription = "description"
    }
}
