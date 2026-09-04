import Foundation

/// One nation's real top-flight division (e.g. the Premier League, Serie A).
public struct League: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let country: String
    /// UEFA coefficient rank at time of writing (1 = top). Purely for
    /// ordering the nation list in the UI.
    public let rank: Int

    public init(id: String, name: String, country: String, rank: Int) {
        self.id = id
        self.name = name
        self.country = country
        self.rank = rank
    }
}
