import Foundation

/// One card shown in a match's deterministic live-watch breakdown — see
/// `MatchDayContentPlanner.cardEvents`. Purely a display/pacing detail, like
/// `GoalEvent`; never changes the match's actual result. `playerName` is
/// always a generic fictional name (see `MatchPlayerNames`), never a real
/// footballer.
public struct CardEvent: Identifiable, Hashable, Sendable {
    public let id: String
    public let minute: Int
    public let isHomeTeam: Bool
    public let playerName: String
    public let isRed: Bool

    public init(id: String, minute: Int, isHomeTeam: Bool, playerName: String, isRed: Bool) {
        self.id = id
        self.minute = minute
        self.isHomeTeam = isHomeTeam
        self.playerName = playerName
        self.isRed = isRed
    }
}
