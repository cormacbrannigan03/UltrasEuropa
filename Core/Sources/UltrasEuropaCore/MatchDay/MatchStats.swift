import Foundation

/// Basic match stats for a fixture whose final score is already fixed — see
/// `MatchStatsEngine.generate`. Purely a display detail for making the
/// match screen and live-watch summary feel more like a real match report;
/// never contradicts the actual `homeScore`/`awayScore`.
public struct MatchStats: Hashable, Sendable {
    public let homeShots: Int
    public let homeShotsOnTarget: Int
    public let homeCorners: Int
    public let homePossession: Int
    public let awayShots: Int
    public let awayShotsOnTarget: Int
    public let awayCorners: Int
    public let awayPossession: Int

    public init(
        homeShots: Int,
        homeShotsOnTarget: Int,
        homeCorners: Int,
        homePossession: Int,
        awayShots: Int,
        awayShotsOnTarget: Int,
        awayCorners: Int,
        awayPossession: Int
    ) {
        self.homeShots = homeShots
        self.homeShotsOnTarget = homeShotsOnTarget
        self.homeCorners = homeCorners
        self.homePossession = homePossession
        self.awayShots = awayShots
        self.awayShotsOnTarget = awayShotsOnTarget
        self.awayCorners = awayCorners
        self.awayPossession = awayPossession
    }
}
