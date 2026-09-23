import Foundation

/// One club's standing in a league table — see `LeagueTableEngine`.
public struct LeagueTableRow: Identifiable, Hashable, Sendable {
    public let clubId: String
    public var played: Int = 0
    public var won: Int = 0
    public var drawn: Int = 0
    public var lost: Int = 0
    public var goalsFor: Int = 0
    public var goalsAgainst: Int = 0

    public var id: String { clubId }
    public var goalDifference: Int { goalsFor - goalsAgainst }
    public var points: Int { won * 3 + drawn }

    public init(clubId: String) {
        self.clubId = clubId
    }
}
