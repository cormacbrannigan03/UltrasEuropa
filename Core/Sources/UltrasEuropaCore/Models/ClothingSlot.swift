import Foundation

/// A wardrobe slot the player can equip one item into. There's no avatar
/// rendering in this app (everything is card/list-based), so "dressing
/// your character" means picking which item is equipped per slot, shown
/// as a selection — not a visual paper-doll.
public enum ClothingSlot: String, Codable, CaseIterable, Hashable, Sendable {
    case top
    case scarf
    case hat

    public var displayName: String {
        switch self {
        case .top: return "Top"
        case .scarf: return "Scarf"
        case .hat: return "Hat"
        }
    }
}
