import Foundation

/// A chant belonging to the player's own crew — not tied to any specific
/// real club or real ultras group. See the content README for why: once
/// club data is real, inventing chants attributed to real fan groups would
/// misrepresent them.
public struct Chant: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let lyrics: String
    /// Not used in v1 (text-only chants); reserved so audio can be added later
    /// without a schema change.
    public let audioAssetName: String?

    public init(
        id: String,
        title: String,
        lyrics: String,
        audioAssetName: String? = nil
    ) {
        self.id = id
        self.title = title
        self.lyrics = lyrics
        self.audioAssetName = audioAssetName
    }
}
