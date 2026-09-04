import Foundation

public enum ItemCategory: String, Codable, CaseIterable, Hashable, Sendable {
    case scarf
    case flag
    case banner
    case pin
    case jersey
}

public struct InventoryItem: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let category: ItemCategory
    public let itemDescription: String
    public let unlockCriteria: AchievementCriteria

    public init(
        id: String,
        name: String,
        category: ItemCategory,
        itemDescription: String,
        unlockCriteria: AchievementCriteria
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.itemDescription = itemDescription
        self.unlockCriteria = unlockCriteria
    }

    enum CodingKeys: String, CodingKey {
        case id, name, category, unlockCriteria
        case itemDescription = "description"
    }
}
