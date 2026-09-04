import Foundation

/// A fictional member of the player's own crew — not a real person, not
/// tied to any real club or real ultras group (see `Chant`/`TifoPhoto` for
/// why). Organized by which rank of the ladder they represent, so the
/// crew's roster grows more senior as the player does.
public struct CrewMember: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let rank: Rank
    public let personality: String
    public let bio: String

    public init(id: String, name: String, rank: Rank, personality: String, bio: String) {
        self.id = id
        self.name = name
        self.rank = rank
        self.personality = personality
        self.bio = bio
    }
}
