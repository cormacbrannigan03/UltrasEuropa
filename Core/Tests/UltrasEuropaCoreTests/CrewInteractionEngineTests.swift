import XCTest
@testable import UltrasEuropaCore

/// A tiny deterministic LCG so tests get a reproducible sequence instead of
/// `SystemRandomNumberGenerator`'s real randomness.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed }
    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return state
    }
}

final class CrewInteractionEngineTests: XCTestCase {

    func testBondDeltaSignMatchesOutcome() {
        var generator = SeededGenerator(seed: 1)
        for seed in 0..<100 {
            generator = SeededGenerator(seed: UInt64(seed))
            let (outcome, _) = CrewInteractionEngine.resolve(
                interaction: .chat, memberName: "Tommy", currentBond: 0, using: &generator
            )
            if outcome.didGoWell {
                XCTAssertGreaterThan(outcome.bondDelta, 0)
            } else {
                XCTAssertLessThan(outcome.bondDelta, 0)
            }
        }
    }

    func testBothOutcomesOccurAcrossManySeeds() {
        var sawSuccess = false
        var sawFailure = false
        for seed in 0..<200 {
            var generator = SeededGenerator(seed: UInt64(seed))
            let (outcome, _) = CrewInteractionEngine.resolve(
                interaction: .teaseThem, memberName: "Iggy", currentBond: 0, using: &generator
            )
            if outcome.didGoWell { sawSuccess = true } else { sawFailure = true }
        }
        XCTAssertTrue(sawSuccess, "Expected at least one success across 200 seeds")
        XCTAssertTrue(sawFailure, "Expected at least one failure across 200 seeds")
    }

    func testNewBondIsClampedToRange() {
        var generator = SeededGenerator(seed: 42)
        let (_, highBond) = CrewInteractionEngine.resolve(
            interaction: .standUpForThem, memberName: "Ana", currentBond: 95, using: &generator
        )
        XCTAssertLessThanOrEqual(highBond, CrewInteractionConstants.bondRange.upperBound)

        var generator2 = SeededGenerator(seed: 7)
        let (_, lowBond) = CrewInteractionEngine.resolve(
            interaction: .standUpForThem, memberName: "Ana", currentBond: -95, using: &generator2
        )
        XCTAssertGreaterThanOrEqual(lowBond, CrewInteractionConstants.bondRange.lowerBound)
    }

    func testSameSeedIsDeterministic() {
        var generatorA = SeededGenerator(seed: 123)
        var generatorB = SeededGenerator(seed: 123)

        let resultA = CrewInteractionEngine.resolve(
            interaction: .shareAChant, memberName: "Dimitri", currentBond: 10, using: &generatorA
        )
        let resultB = CrewInteractionEngine.resolve(
            interaction: .shareAChant, memberName: "Dimitri", currentBond: 10, using: &generatorB
        )

        XCTAssertEqual(resultA.outcome.didGoWell, resultB.outcome.didGoWell)
        XCTAssertEqual(resultA.outcome.bondDelta, resultB.outcome.bondDelta)
        XCTAssertEqual(resultA.newBond, resultB.newBond)
        XCTAssertEqual(resultA.outcome.message, resultB.outcome.message)
    }

    func testMessageMentionsMemberName() {
        var generator = SeededGenerator(seed: 5)
        let (outcome, _) = CrewInteractionEngine.resolve(
            interaction: .inviteToMatch, memberName: "Priya", currentBond: 0, using: &generator
        )
        XCTAssertTrue(outcome.message.contains("Priya"))
    }
}

final class RelationshipLevelTests: XCTestCase {

    func testBoundaries() {
        XCTAssertEqual(RelationshipLevel.level(forBond: -100), .rival)
        XCTAssertEqual(RelationshipLevel.level(forBond: -41), .rival)
        XCTAssertEqual(RelationshipLevel.level(forBond: -40), .cold)
        XCTAssertEqual(RelationshipLevel.level(forBond: -1), .cold)
        XCTAssertEqual(RelationshipLevel.level(forBond: 0), .stranger)
        XCTAssertEqual(RelationshipLevel.level(forBond: 19), .stranger)
        XCTAssertEqual(RelationshipLevel.level(forBond: 20), .acquaintance)
        XCTAssertEqual(RelationshipLevel.level(forBond: 39), .acquaintance)
        XCTAssertEqual(RelationshipLevel.level(forBond: 40), .friend)
        XCTAssertEqual(RelationshipLevel.level(forBond: 59), .friend)
        XCTAssertEqual(RelationshipLevel.level(forBond: 60), .closeFriend)
        XCTAssertEqual(RelationshipLevel.level(forBond: 84), .closeFriend)
        XCTAssertEqual(RelationshipLevel.level(forBond: 85), .bondedForLife)
        XCTAssertEqual(RelationshipLevel.level(forBond: 100), .bondedForLife)
    }
}
