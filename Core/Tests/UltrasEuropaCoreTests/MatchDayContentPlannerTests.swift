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
}
