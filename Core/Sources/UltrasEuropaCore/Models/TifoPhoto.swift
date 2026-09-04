import Foundation

/// A tifo display belonging to the player's own crew — not tied to any
/// specific real club, group, or match. See `Chant` for why.
public struct TifoPhoto: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let caption: String
    /// `nil` means the app should render a generated placeholder card
    /// instead of a real photo.
    public let imageAssetName: String?

    public init(
        id: String,
        caption: String,
        imageAssetName: String? = nil
    ) {
        self.id = id
        self.caption = caption
        self.imageAssetName = imageAssetName
    }
}
