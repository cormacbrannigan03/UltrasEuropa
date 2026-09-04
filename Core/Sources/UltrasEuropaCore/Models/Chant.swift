import Foundation

public struct Chant: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let clubId: String
    public let title: String
    public let lyrics: String
    /// Not used in v1 (text-only chants); reserved so audio can be added later
    /// without a schema change.
    public let audioAssetName: String?

    public init(
        id: String,
        clubId: String,
        title: String,
        lyrics: String,
        audioAssetName: String? = nil
    ) {
        self.id = id
        self.clubId = clubId
        self.title = title
        self.lyrics = lyrics
        self.audioAssetName = audioAssetName
    }
}
