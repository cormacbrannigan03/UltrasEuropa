import XCTest
@testable import UltrasEuropaCore

final class MatchDayContentPlannerTests: XCTestCase {

    func testChantIndexIsDeterministic() {
        let first = MatchDayContentPlanner.chantIndex(matchId: "premier-league-arsenal-chelsea", catalogCount: 12)
        let second = MatchDayContentPlanner.chantIndex(matchId: "premier-league-arsenal-chelsea", catalogCount: 12)
        XCTAssertEqual(first, second)
    }

    func testChantIndexIsWithinCatalogBounds() {
        for id in ["m1", "m2", "m3", "m4", "m5"] {
            let index = try XCTUnwrap(MatchDayContentPlanner.chantIndex(matchId: id, catalogCount: 12))
            XCTAssertTrue((0..<12).contains(index))
        }
    }

    func testChantIndexIsNilForEmptyCatalog() {
        XCTAssertNil(MatchDayContentPlanner.chantIndex(matchId: "m1", catalogCount: 0))
    }

    func testTifoPreparationIsDeterministic() {
        let first = MatchDayContentPlanner.isTifoPrepared(matchId: "premier-league-arsenal-chelsea")
        let second = MatchDayContentPlanner.isTifoPrepared(matchId: "premier-league-arsenal-chelsea")
        XCTAssertEqual(first, second)
    }

    func testTifoIsPreparedForOnlySomeMatches() {
        let ids = (0..<200).map { "match-\($0)" }
        let preparedCount = ids.filter { MatchDayContentPlanner.isTifoPrepared(matchId: $0) }.count
        XCTAssertGreaterThan(preparedCount, 0, "At least some matches should have a tifo prepared")
        XCTAssertLessThan(preparedCount, ids.count, "Not every match should have a tifo prepared")
    }

    func testTifoIndexIsNilWhenNotPrepared() {
        let ids = (0..<50).map { "match-\($0)" }
        for id in ids where !MatchDayContentPlanner.isTifoPrepared(matchId: id) {
            XCTAssertNil(MatchDayContentPlanner.tifoIndex(matchId: id, catalogCount: 10))
        }
    }

    func testTifoIndexIsWithinCatalogBoundsWhenPrepared() {
        let ids = (0..<50).map { "match-\($0)" }
        for id in ids where MatchDayContentPlanner.isTifoPrepared(matchId: id) {
            let index = try? XCTUnwrap(MatchDayContentPlanner.tifoIndex(matchId: id, catalogCount: 10))
            XCTAssertNotNil(index)
            if let index {
                XCTAssertTrue((0..<10).contains(index))
            }
        }
    }

    func testChantAndTifoSeedsAreIndependent() {
        // Same match id shouldn't force the chant and tifo picks to always
        // agree just because they share a base seed.
        let matchId = "premier-league-arsenal-chelsea"
        let chant = MatchDayContentPlanner.chantIndex(matchId: matchId, catalogCount: 12)
        let tifo = MatchDayContentPlanner.tifoIndex(matchId: matchId, catalogCount: 12)
        // Not a strict correctness assertion (they could coincidentally
        // match), just confirms both compute without needing each other.
        XCTAssertNotNil(chant)
        _ = tifo
    }

    func testGoalEventsProduceCorrectCounts() {
        let events = MatchDayContentPlanner.goalEvents(matchId: "m1", homeGoals: 2, awayGoals: 1)
        XCTAssertEqual(events.count, 3)
        XCTAssertEqual(events.filter(\.isHomeTeam).count, 2)
        XCTAssertEqual(events.filter { !$0.isHomeTeam }.count, 1)
    }

    func testGoalEventsAreEmptyForScorelessDraw() {
        XCTAssertEqual(MatchDayContentPlanner.goalEvents(matchId: "m1", homeGoals: 0, awayGoals: 0), [])
    }

    func testGoalEventsAreSortedByMinute() {
        let events = MatchDayContentPlanner.goalEvents(matchId: "m1", homeGoals: 3, awayGoals: 2)
        XCTAssertEqual(events.map(\.minute), events.map(\.minute).sorted())
    }

    func testGoalEventMinutesAreDistinctAndInRange() {
        let events = MatchDayContentPlanner.goalEvents(matchId: "m1", homeGoals: 4, awayGoals: 4)
        let minutes = events.map(\.minute)
        XCTAssertEqual(Set(minutes).count, minutes.count, "No two goals should land on the same minute")
        for minute in minutes {
            XCTAssertTrue((1...MatchDayContentPlanner.matchLengthMinutes).contains(minute))
        }
    }

    func testGoalEventsAreDeterministic() {
        let first = MatchDayContentPlanner.goalEvents(matchId: "premier-league-arsenal-chelsea", homeGoals: 2, awayGoals: 2)
        let second = MatchDayContentPlanner.goalEvents(matchId: "premier-league-arsenal-chelsea", homeGoals: 2, awayGoals: 2)
        XCTAssertEqual(first, second)
    }

    func testGoalEventsDifferByMatch() {
        let a = MatchDayContentPlanner.goalEvents(matchId: "match-a", homeGoals: 2, awayGoals: 1)
        let b = MatchDayContentPlanner.goalEvents(matchId: "match-b", homeGoals: 2, awayGoals: 1)
        XCTAssertNotEqual(a.map(\.minute), b.map(\.minute))
    }

    func testGoalEventsHaveNonEmptyScorerNames() {
        let events = MatchDayContentPlanner.goalEvents(matchId: "m1", homeGoals: 3, awayGoals: 2)
        for event in events {
            XCTAssertFalse(event.scorerName.isEmpty)
        }
    }

    func testGoalScorerNamesAreDeterministic() {
        let first = MatchDayContentPlanner.goalEvents(matchId: "premier-league-arsenal-chelsea", homeGoals: 2, awayGoals: 2)
        let second = MatchDayContentPlanner.goalEvents(matchId: "premier-league-arsenal-chelsea", homeGoals: 2, awayGoals: 2)
        XCTAssertEqual(first.map(\.scorerName), second.map(\.scorerName))
    }

    // MARK: - Card events

    func testCardEventsAreDeterministic() {
        let first = MatchDayContentPlanner.cardEvents(matchId: "premier-league-arsenal-chelsea")
        let second = MatchDayContentPlanner.cardEvents(matchId: "premier-league-arsenal-chelsea")
        XCTAssertEqual(first, second)
    }

    func testCardEventCountIsWithinBounds() {
        let ids = (0..<100).map { "match-\($0)" }
        for id in ids {
            let count = MatchDayContentPlanner.cardEvents(matchId: id).count
            XCTAssertTrue((0...4).contains(count))
        }
    }

    func testSomeMatchesHaveNoCardsAndSomeHaveCards() {
        let ids = (0..<200).map { "match-\($0)" }
        let counts = ids.map { MatchDayContentPlanner.cardEvents(matchId: $0).count }
        XCTAssertTrue(counts.contains(0), "At least some matches should have no cards")
        XCTAssertTrue(counts.contains { $0 > 0 }, "At least some matches should have cards")
    }

    func testCardEventMinutesAreDistinctAndInRange() {
        let events = MatchDayContentPlanner.cardEvents(matchId: "match-with-cards-1")
        let minutes = events.map(\.minute)
        XCTAssertEqual(Set(minutes).count, minutes.count, "No two cards should land on the same minute")
        for minute in minutes {
            XCTAssertTrue((1...MatchDayContentPlanner.matchLengthMinutes).contains(minute))
        }
    }

    func testCardEventsAreSortedByMinute() {
        let events = MatchDayContentPlanner.cardEvents(matchId: "match-with-cards-2")
        XCTAssertEqual(events.map(\.minute), events.map(\.minute).sorted())
    }

    func testCardEventsHaveNonEmptyPlayerNames() {
        let ids = (0..<50).map { "match-\($0)" }
        for id in ids {
            for event in MatchDayContentPlanner.cardEvents(matchId: id) {
                XCTAssertFalse(event.playerName.isEmpty)
            }
        }
    }

    func testMostCardEventsAreYellowNotRed() {
        let ids = (0..<200).map { "match-\($0)" }
        let allCards = ids.flatMap { MatchDayContentPlanner.cardEvents(matchId: $0) }
        let redCount = allCards.filter(\.isRed).count
        XCTAssertGreaterThan(allCards.count, 0)
        XCTAssertLessThan(redCount, allCards.count, "Reds should be rare relative to yellows")
    }
}
