import Foundation

public struct Match: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let homeClubId: String
    public let awayClubId: String
    public let date: Date
    public let competition: String
    public let venue: String
    /// `nil` means the fixture hasn't been played yet.
    public let homeScore: Int?
    public let awayScore: Int?

    public init(
        id: String,
        homeClubId: String,
        awayClubId: String,
        date: Date,
        competition: String,
        venue: String,
        homeScore: Int?,
        awayScore: Int?
    ) {
        self.id = id
        self.homeClubId = homeClubId
        self.awayClubId = awayClubId
        self.date = date
        self.competition = competition
        self.venue = venue
        self.homeScore = homeScore
        self.awayScore = awayScore
    }

    public var isPlayed: Bool {
        homeScore != nil && awayScore != nil
    }
}
