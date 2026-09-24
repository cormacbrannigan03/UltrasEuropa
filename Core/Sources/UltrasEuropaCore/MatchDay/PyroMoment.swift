import Foundation

/// When the player plans to light the pyro they brought to a match — chosen
/// up front on the match screen, then confirmed live when that moment
/// actually arrives during the live-watch beat (see `MatchDayCutsceneView`).
/// Purely a player choice; no chance or engine logic attached to it.
public enum PyroMoment: String, CaseIterable, Codable, Hashable, Sendable {
    case kickoff
    case afterGoal

    public var displayName: String {
        switch self {
        case .kickoff: return "At Kickoff"
        case .afterGoal: return "After a Goal"
        }
    }
}
