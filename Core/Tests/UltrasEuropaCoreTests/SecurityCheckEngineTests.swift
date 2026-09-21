import XCTest
@testable import UltrasEuropaCore

final class SecurityCheckEngineTests: XCTestCase {

    func testBothOutcomesOccurAcrossManySeeds() {
        var sawSuccess = false
        var sawFailure = false
        for seed in 0..<200 {
            var generator = SeededGenerator(seed: UInt64(seed))
            if SecurityCheckEngine.resolvePyroSearch(spot: .insideJacket, using: &generator) {
                sawSuccess = true
            } else {
                sawFailure = true
            }
        }
        XCTAssertTrue(sawSuccess, "Should sometimes get pyro through security")
        XCTAssertTrue(sawFailure, "Should sometimes get caught")
    }

    func testIsDeterministicForAGivenSeed() {
        var first = SeededGenerator(seed: 42)
        var second = SeededGenerator(seed: 42)
        let firstResult = SecurityCheckEngine.resolvePyroSearch(spot: .rolledInScarf, using: &first)
        let secondResult = SecurityCheckEngine.resolvePyroSearch(spot: .rolledInScarf, using: &second)
        XCTAssertEqual(firstResult, secondResult)
    }

    func testSaferHidingSpotsSucceedMoreOftenOverManySeeds() {
        func successRate(_ spot: PyroHidingSpot) -> Double {
            var successes = 0
            for seed in 0..<500 {
                var generator = SeededGenerator(seed: UInt64(seed))
                if SecurityCheckEngine.resolvePyroSearch(spot: spot, using: &generator) {
                    successes += 1
                }
            }
            return Double(successes) / 500
        }

        XCTAssertGreaterThan(successRate(.tapedToLeg), successRate(.insideJacket))
    }
}
