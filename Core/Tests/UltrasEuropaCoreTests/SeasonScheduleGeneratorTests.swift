import XCTest
@testable import UltrasEuropaCore

final class SeasonScheduleGeneratorTests: XCTestCase {

    private func makeClub(_ id: String) -> Club {
        Club(
            id: id, name: id.capitalized, city: id.capitalized, country: "Testland",
            leagueId: "test-league", founded: 1900, stadiumName: "\(id.capitalized) Arena",
            primaryColorHex: "#112233", secondaryColorHex: "#445566"
        )
    }

    private var league: League { League(id: "test-league", name: "Test League", country: "Testland", rank: 1) }

    private func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    func testEveryOrderedPairPlaysExactlyOnce() {
        let clubs = (1...8).map { makeClub("club\($0)") }
        let calendar = utcCalendar()
        let today = calendar.date(from: DateComponents(year: 2026, month: 9, day: 3))!

        let matches = SeasonScheduleGenerator.generateSeason(league: league, clubs: clubs, today: today, calendar: calendar)

        // n*(n-1) fixtures for a double round robin of n teams.
        XCTAssertEqual(matches.count, clubs.count * (clubs.count - 1))

        var seenPairs = Set<String>()
        for match in matches {
            XCTAssertNotEqual(match.homeClubId, match.awayClubId, "A club should never play itself")
            let key = "\(match.homeClubId)->\(match.awayClubId)"
            XCTAssertFalse(seenPairs.contains(key), "Ordered pairing \(key) appeared more than once")
            seenPairs.insert(key)
        }
        XCTAssertEqual(seenPairs.count, clubs.count * (clubs.count - 1))
    }

    func testEachClubPlaysEveryOtherClubHomeAndAway() {
        let clubs = (1...6).map { makeClub("club\($0)") }
        let calendar = utcCalendar()
        let today = calendar.date(from: DateComponents(year: 2026, month: 9, day: 3))!
        let matches = SeasonScheduleGenerator.generateSeason(league: league, clubs: clubs, today: today, calendar: calendar)

        for club in clubs {
            let opponents = clubs.filter { $0.id != club.id }
            for opponent in opponents {
                let hasHomeFixture = matches.contains { $0.homeClubId == club.id && $0.awayClubId == opponent.id }
                let hasAwayFixture = matches.contains { $0.homeClubId == opponent.id && $0.awayClubId == club.id }
                XCTAssertTrue(hasHomeFixture, "\(club.id) should host \(opponent.id) once")
                XCTAssertTrue(hasAwayFixture, "\(club.id) should travel to \(opponent.id) once")
            }
        }
    }

    func testGenerationIsDeterministic() {
        let clubs = (1...10).map { makeClub("club\($0)") }
        let calendar = utcCalendar()
        let today = calendar.date(from: DateComponents(year: 2026, month: 9, day: 3))!

        let first = SeasonScheduleGenerator.generateSeason(league: league, clubs: clubs, today: today, calendar: calendar)
        let second = SeasonScheduleGenerator.generateSeason(league: league, clubs: clubs, today: today, calendar: calendar)

        XCTAssertEqual(first.map(\.id), second.map(\.id))
        XCTAssertEqual(first.map(\.date), second.map(\.date))
        XCTAssertEqual(first.map(\.homeScore), second.map(\.homeScore))
        XCTAssertEqual(first.map(\.awayScore), second.map(\.awayScore))
    }

    func testPastFixturesHaveScoresAndFutureFixturesDoNot() {
        let clubs = (1...6).map { makeClub("club\($0)") }
        let calendar = utcCalendar()
        let today = calendar.date(from: DateComponents(year: 2026, month: 9, day: 3))!
        let matches = SeasonScheduleGenerator.generateSeason(league: league, clubs: clubs, today: today, calendar: calendar)

        XCTAssertTrue(matches.contains { $0.date <= today })
        XCTAssertTrue(matches.contains { $0.date > today })

        for match in matches {
            if match.date <= today {
                XCTAssertTrue(match.isPlayed, "Fixture dated on/before today should have a score")
            } else {
                XCTAssertFalse(match.isPlayed, "Fixture dated after today should not have a score yet")
            }
        }
    }

    func testOddTeamCountStillProducesAValidSchedule() {
        let clubs = (1...7).map { makeClub("club\($0)") }
        let calendar = utcCalendar()
        let today = calendar.date(from: DateComponents(year: 2026, month: 9, day: 3))!
        let matches = SeasonScheduleGenerator.generateSeason(league: league, clubs: clubs, today: today, calendar: calendar)

        XCTAssertEqual(matches.count, clubs.count * (clubs.count - 1))
        for match in matches {
            XCTAssertNotEqual(match.homeClubId, match.awayClubId)
        }
    }
}
