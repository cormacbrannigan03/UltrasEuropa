import Foundation

public struct TifoPhoto: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let clubId: String
    public let caption: String
    public let matchId: String?
    /// `nil` means the app should render a generated placeholder card
    /// (gradient in the club's colors) instead of a real photo.
    public let imageAssetName: String?

    public init(
        id: String,
        clubId: String,
        caption: String,
        matchId: String?,
        imageAssetName: String?
    ) {
        self.id = id
        self.clubId = clubId
        self.caption = caption
        self.matchId = matchId
        self.imageAssetName = imageAssetName
    }
}
