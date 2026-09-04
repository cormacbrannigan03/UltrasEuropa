import Foundation

public struct UltrasGroup: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let clubId: String
    public let name: String
    public let founded: Int
    public let symbols: [String]
    public let colors: [String]
    public let groupDescription: String

    public init(
        id: String,
        clubId: String,
        name: String,
        founded: Int,
        symbols: [String],
        colors: [String],
        groupDescription: String
    ) {
        self.id = id
        self.clubId = clubId
        self.name = name
        self.founded = founded
        self.symbols = symbols
        self.colors = colors
        self.groupDescription = groupDescription
    }

    enum CodingKeys: String, CodingKey {
        case id, clubId, name, founded, symbols, colors
        case groupDescription = "description"
    }
}
