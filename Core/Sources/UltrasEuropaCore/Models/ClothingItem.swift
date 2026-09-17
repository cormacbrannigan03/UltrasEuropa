import Foundation

/// A wardrobe item. Bundled starter items (`isRangeItem == false`) are
/// generic and available from the start. `isRangeItem == true` marks an
/// item the player designed themselves after reaching Capo — those aren't
/// bundled content, they're created at runtime (see `CharacterStore.launchClothingRange`).
public struct ClothingItem: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let slot: ClothingSlot
    public let clothingDescription: String
    public let isRangeItem: Bool

    public init(
        id: String,
        name: String,
        slot: ClothingSlot,
        clothingDescription: String,
        isRangeItem: Bool = false
    ) {
        self.id = id
        self.name = name
        self.slot = slot
        self.clothingDescription = clothingDescription
        self.isRangeItem = isRangeItem
    }

    enum CodingKeys: String, CodingKey {
        case id, name, slot, isRangeItem
        case clothingDescription = "description"
    }
}
