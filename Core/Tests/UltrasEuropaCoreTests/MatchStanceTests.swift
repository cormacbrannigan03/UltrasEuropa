import XCTest
@testable import UltrasEuropaCore

final class MatchStanceTests: XCTestCase {

    func testLowKeyStancesAddNoHeat() {
        XCTAssertEqual(MatchStance.singNonStop.heatPerCheckpoint, 0)
        XCTAssertEqual(MatchStance.watchQuietly.heatPerCheckpoint, 0)
    }

    func testWindUpRivalsIsRiskierThanFilmForSocials() {
        XCTAssertGreaterThan(MatchStance.windUpRivals.heatPerCheckpoint, MatchStance.filmForSocials.heatPerCheckpoint)
        XCTAssertGreaterThan(MatchStance.filmForSocials.heatPerCheckpoint, 0)
    }

    func testEveryStanceHasADistinctActivityType() {
        let activityTypes = Set(MatchStance.allCases.map(\.activityType))
        XCTAssertEqual(activityTypes.count, MatchStance.allCases.count)
    }

    func testEveryStanceHasNonEmptyDisplayText() {
        for stance in MatchStance.allCases {
            XCTAssertFalse(stance.displayName.isEmpty)
            XCTAssertFalse(stance.selectionDescription.isEmpty)
        }
    }
}

final class MatchStanceConstantsTests: XCTestCase {

    func testEveryStanceHasFifteenDiaryLines() {
        for stance in MatchStance.allCases {
            XCTAssertEqual(
                MatchStanceConstants.diaryLines[stance]?.count, 15,
                "\(stance) should have exactly 15 diary lines"
            )
        }
    }

    func testAllLinesWithinAStanceAreUnique() {
        for stance in MatchStance.allCases {
            let pool = MatchStanceConstants.diaryLines[stance] ?? []
            XCTAssertEqual(Set(pool).count, pool.count, "\(stance) has duplicate lines")
        }
    }

    func testRandomLineComesFromThePool() {
        var generator = SeededGenerator(seed: 5)
        for stance in MatchStance.allCases {
            let line = MatchStanceConstants.randomLine(for: stance, using: &generator)
            XCTAssertTrue(MatchStanceConstants.diaryLines[stance]?.contains(line) ?? false)
        }
    }

    func testRandomLineIsDeterministicForTheSameSeed() {
        var generatorA = SeededGenerator(seed: 42)
        var generatorB = SeededGenerator(seed: 42)
        let lineA = MatchStanceConstants.randomLine(for: .singNonStop, using: &generatorA)
        let lineB = MatchStanceConstants.randomLine(for: .singNonStop, using: &generatorB)
        XCTAssertEqual(lineA, lineB)
    }

    func testRandomLineAvoidsImmediateRepeatWhenPossible() {
        let stance = MatchStance.windUpRivals
        var seedGenerator = SeededGenerator(seed: 9)
        let first = MatchStanceConstants.randomLine(for: stance, using: &seedGenerator)

        var sawDifferentLine = false
        for seed in 0..<50 {
            var generator = SeededGenerator(seed: UInt64(seed + 500))
            let next = MatchStanceConstants.randomLine(for: stance, excluding: first, using: &generator)
            if next != first { sawDifferentLine = true }
        }
        XCTAssertTrue(sawDifferentLine, "Expected at least one different line across many seeds")
    }
}
