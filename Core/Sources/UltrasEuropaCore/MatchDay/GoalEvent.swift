import Foundation

/// One goal in a match's deterministic minute-by-minute breakdown — see
/// `MatchDayContentPlanner.goalEvents`. Purely a display/pacing detail for
/// watching a match "live"; the final score it adds up to is always the
/// same synthetic result `SeasonScheduleGenerator` already fixed for that
/// match, never a new or different outcome.
public struct GoalEvent: Identifiable, Hashable, Sendable {
    public let id: String
    public let minute: Int
    public let isHomeTeam: Bool
    /// Always a generic fictional name (see `MatchPlayerNames`), never a
    /// real footballer.
    public let scorerName: String

    public init(id: String, minute: Int, isHomeTeam: Bool, scorerName: String) {
        self.id = id
        self.minute = minute
        self.isHomeTeam = isHomeTeam
        self.scorerName = scorerName
    }
}
