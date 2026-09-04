import Foundation

public struct Club: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let city: String
    public let country: String
    public let leagueId: String
    public let founded: Int
    public let stadiumName: String
    public let primaryColorHex: String
    public let secondaryColorHex: String
    /// Name of an asset-catalog image for the club crest. `nil` means the app
    /// should render a generated placeholder (see `PlaceholderArt` usage in the App layer).
    public let crestAssetName: String?
    /// Short factual note, when available. Left `nil` for most clubs rather
    /// than inventing narrative history text at bulk scale — see the
    /// content README for why.
    public let history: String?

    public init(
        id: String,
        name: String,
        city: String,
        country: String,
        leagueId: String,
        founded: Int,
        stadiumName: String,
        primaryColorHex: String,
        secondaryColorHex: String,
        crestAssetName: String? = nil,
        history: String? = nil
    ) {
        self.id = id
        self.name = name
        self.city = city
        self.country = country
        self.leagueId = leagueId
        self.founded = founded
        self.stadiumName = stadiumName
        self.primaryColorHex = primaryColorHex
        self.secondaryColorHex = secondaryColorHex
        self.crestAssetName = crestAssetName
        self.history = history
    }
}
