import XCTest
@testable import UltrasEuropaCore

final class MatchStatsEngineTests: XCTestCase {

    func testStatsAreDeterministic() {
        let first = MatchStatsEngine.generate(matchId: "premier-league-arsenal-chelsea", homeGoals: 2, awayGoals: 1)
        let second = MatchStatsEngine.generate(matchId: "premier-league-arsenal-chelsea", homeGoals: 2, awayGoals: 1)
        XCTAssertEqual(first, second)
    }

    func testStatsDifferByMatch() {
        let a = MatchStatsEngine.generate(matchId: "match-a", homeGoals: 1, awayGoals: 1)
        let b = MatchStatsEngine.generate(matchId: "match-b", homeGoals: 1, awayGoals: 1)
        XCTAssertNotEqual(a, b)
    }

    func testShotsOnTargetNeverExceedShots() {
        for id in (0..<100).map({ "match-\($0)" }) {
            for (homeGoals, awayGoals) in [(0, 0), (1, 0), (0, 3), (4, 4), (5, 0)] {
                let stats = MatchStatsEngine.generate(matchId: id, homeGoals: homeGoals, awayGoals: awayGoals)
                XCTAssertLessThanOrEqual(stats.homeShotsOnTarget, stats.homeShots)
                XCTAssertLessThanOrEqual(stats.awayShotsOnTarget, stats.awayShots)
            }
        }
    }

    func testShotsOnTargetCoverGoalsScored() {
        for id in (0..<100).map({ "match-\($0)" }) {
            let stats = MatchStatsEngine.generate(matchId: id, homeGoals: 3, awayGoals: 2)
            XCTAssertGreaterThanOrEqual(stats.homeShotsOnTarget, 3)
            XCTAssertGreaterThanOrEqual(stats.awayShotsOnTarget, 2)
        }
    }

    func testPossessionAlwaysSumsToOneHundred() {
        for id in (0..<100).map({ "match-\($0)" }) {
            let stats = MatchStatsEngine.generate(matchId: id, homeGoals: 1, awayGoals: 1)
            XCTAssertEqual(stats.homePossession + stats.awayPossession, 100)
        }
    }

    func testPossessionStaysWithinPlausibleBounds() {
        for id in (0..<100).map({ "match-\($0)" }) {
            let stats = MatchStatsEngine.generate(matchId: id, homeGoals: 4, awayGoals: 0)
            XCTAssertTrue((25...75).contains(stats.homePossession))
            XCTAssertTrue((25...75).contains(stats.awayPossession))
        }
    }

    func testShotsAndCornersAreNeverNegative() {
        for id in (0..<100).map({ "match-\($0)" }) {
            let stats = MatchStatsEngine.generate(matchId: id, homeGoals: 0, awayGoals: 5)
            XCTAssertGreaterThanOrEqual(stats.homeShots, 0)
            XCTAssertGreaterThanOrEqual(stats.awayShots, 0)
            XCTAssertGreaterThanOrEqual(stats.homeCorners, 0)
            XCTAssertGreaterThanOrEqual(stats.awayCorners, 0)
        }
    }

    func testWinningSideTendsToHaveMoreShots() {
        // Not a strict guarantee for every seed, but across many matches the
        // side that scored heavily more should out-shoot its opponent more
        // often than not.
        let ids = (0..<200).map { "match-\($0)" }
        let homeAheadCount = ids.filter { MatchStatsEngine.generate(matchId: $0, homeGoals: 4, awayGoals: 0).homeShots > MatchStatsEngine.generate(matchId: $0, homeGoals: 4, awayGoals: 0).awayShots }.count
        XCTAssertGreaterThan(homeAheadCount, ids.count / 2)
    }
}
