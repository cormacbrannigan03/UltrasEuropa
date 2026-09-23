import XCTest
@testable import UltrasEuropaCore

final class LeagueTableEngineTests: XCTestCase {

    private func match(
        home: String, away: String, homeScore: Int?, awayScore: Int?, date: Date = .now
    ) -> Match {
        Match(
            id: "\(home)-\(away)-\(date.timeIntervalSince1970)",
            homeClubId: home, awayClubId: away, date: date,
            competition: "Test League", venue: "Test Stadium",
            homeScore: homeScore, awayScore: awayScore
        )
    }

    func testUnplayedMatchesDontCountTowardStandings() {
        let matches = [match(home: "a", away: "b", homeScore: nil, awayScore: nil)]
        let rows = LeagueTableEngine.standings(matches: matches, clubIds: ["a", "b"])
        XCTAssertEqual(rows.first { $0.clubId == "a" }?.played, 0)
        XCTAssertEqual(rows.first { $0.clubId == "b" }?.played, 0)
    }

    func testWinDrawLossAwardCorrectPoints() {
        let matches = [
            match(home: "a", away: "b", homeScore: 2, awayScore: 0), // a wins
            match(home: "b", away: "a", homeScore: 1, awayScore: 1), // draw
        ]
        let rows = LeagueTableEngine.standings(matches: matches, clubIds: ["a", "b"])
        let a = rows.first { $0.clubId == "a" }!
        let b = rows.first { $0.clubId == "b" }!

        XCTAssertEqual(a.won, 1)
        XCTAssertEqual(a.drawn, 1)
        XCTAssertEqual(a.lost, 0)
        XCTAssertEqual(a.points, 4)

        XCTAssertEqual(b.won, 0)
        XCTAssertEqual(b.drawn, 1)
        XCTAssertEqual(b.lost, 1)
        XCTAssertEqual(b.points, 1)
    }

    func testGoalsForAndAgainstAccumulateAcrossHomeAndAway() {
        let matches = [
            match(home: "a", away: "b", homeScore: 3, awayScore: 1),
            match(home: "b", away: "a", homeScore: 2, awayScore: 2),
        ]
        let rows = LeagueTableEngine.standings(matches: matches, clubIds: ["a", "b"])
        let a = rows.first { $0.clubId == "a" }!

        XCTAssertEqual(a.goalsFor, 5) // 3 + 2
        XCTAssertEqual(a.goalsAgainst, 3) // 1 + 2
        XCTAssertEqual(a.goalDifference, 2)
    }

    func testSortsByPointsThenGoalDifferenceThenGoalsFor() {
        let matches = [
            match(home: "a", away: "x", homeScore: 5, awayScore: 0), // a: 3pts, GD +5
            match(home: "b", away: "x", homeScore: 1, awayScore: 0), // b: 3pts, GD +1
            match(home: "c", away: "x", homeScore: 0, awayScore: 0), // c: 1pt
        ]
        let rows = LeagueTableEngine.standings(matches: matches, clubIds: ["a", "b", "c", "x"])
        let order = rows.map(\.clubId)
        XCTAssertEqual(Array(order.prefix(3)), ["a", "b", "c"])
    }

    func testClubsNotInClubIdsAreIgnored() {
        let matches = [match(home: "a", away: "outsider", homeScore: 2, awayScore: 1)]
        let rows = LeagueTableEngine.standings(matches: matches, clubIds: ["a", "b"])
        XCTAssertNil(rows.first { $0.clubId == "outsider" })
        // "a" played against a club outside the league list, so its own
        // stats shouldn't be counted either.
        XCTAssertEqual(rows.first { $0.clubId == "a" }?.played, 0)
    }

    func testEveryClubIdProducesARowEvenWithNoMatches() {
        let rows = LeagueTableEngine.standings(matches: [], clubIds: ["a", "b", "c"])
        XCTAssertEqual(Set(rows.map(\.clubId)), Set(["a", "b", "c"]))
        XCTAssertTrue(rows.allSatisfy { $0.played == 0 && $0.points == 0 })
    }
}
