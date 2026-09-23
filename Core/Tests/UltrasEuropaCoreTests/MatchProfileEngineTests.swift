import XCTest
@testable import UltrasEuropaCore

final class MatchProfileEngineTests: XCTestCase {

    func testTwoGiantClubsAreCategoryOne() {
        let category = MatchProfileEngine.category(
            matchId: "giant-clash", homeClubPrestigeTier: 5, awayClubPrestigeTier: 5
        )
        XCTAssertEqual(category, .one)
    }

    func testTwoSmallClubsAreCategoryThree() {
        let category = MatchProfileEngine.category(
            matchId: "small-clash", homeClubPrestigeTier: 1, awayClubPrestigeTier: 1
        )
        XCTAssertEqual(category, .three)
    }

    func testSameInputsAlwaysProduceTheSameCategory() {
        let first = MatchProfileEngine.category(matchId: "fixture-1", homeClubPrestigeTier: 3, awayClubPrestigeTier: 4)
        let second = MatchProfileEngine.category(matchId: "fixture-1", homeClubPrestigeTier: 3, awayClubPrestigeTier: 4)
        XCTAssertEqual(first, second)
    }

    func testDifferentMatchIdsCanDifferAtTheSamePrestige() {
        // Combined prestige of 5 sits right on a category boundary (the
        // seeded bump of 0-2 can push the score to either side of it), so
        // different match ids at this same combined prestige should land
        // in more than one category — it isn't purely a function of
        // prestige alone.
        var categories = Set<MatchCategory>()
        for i in 0..<30 {
            let category = MatchProfileEngine.category(
                matchId: "fixture-\(i)", homeClubPrestigeTier: 3, awayClubPrestigeTier: 2
            )
            categories.insert(category)
        }
        XCTAssertGreaterThan(categories.count, 1, "Expected some variety across different match ids")
    }
}
