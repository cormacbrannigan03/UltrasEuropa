import XCTest
@testable import UltrasEuropaCore

final class AwayTicketAllocationEngineTests: XCTestCase {

    func testChanceRisesFromBaseToGuaranteed() {
        XCTAssertEqual(ProgressionConstants.awayTicketChance(awayLoyaltyPoints: 0, prestigeTier: 3), 0.3, accuracy: 0.001)
        let threshold = ProgressionConstants.awayTicketGuaranteedThreshold(forPrestigeTier: 3)
        XCTAssertEqual(ProgressionConstants.awayTicketChance(awayLoyaltyPoints: threshold, prestigeTier: 3), 1.0, accuracy: 0.001)
        // Never decreases past the guarantee.
        XCTAssertEqual(ProgressionConstants.awayTicketChance(awayLoyaltyPoints: threshold * 2, prestigeTier: 3), 1.0, accuracy: 0.001)
    }

    func testBiggerClubsNeedMoreAwayLoyaltyForTheSameChance() {
        let smallClubChance = ProgressionConstants.awayTicketChance(awayLoyaltyPoints: 30, prestigeTier: 1)
        let giantClubChance = ProgressionConstants.awayTicketChance(awayLoyaltyPoints: 30, prestigeTier: 5)
        XCTAssertGreaterThan(smallClubChance, giantClubChance)
    }

    func testBothOutcomesOccurAcrossManySeeds() {
        var sawSuccess = false
        var sawFailure = false
        for seed in 0..<200 {
            var generator = SeededGenerator(seed: UInt64(seed))
            let outcome = AwayTicketAllocationEngine.resolve(
                currentAwayLoyaltyPoints: 0, prestigeTier: 3, using: &generator
            )
            if outcome.gotTicket { sawSuccess = true } else { sawFailure = true }
        }
        XCTAssertTrue(sawSuccess)
        XCTAssertTrue(sawFailure)
    }

    func testZeroLoyaltyNeverGuaranteesAndAlwaysGainsSomeLoyalty() {
        for seed in 0..<50 {
            var generator = SeededGenerator(seed: UInt64(seed))
            let outcome = AwayTicketAllocationEngine.resolve(
                currentAwayLoyaltyPoints: 0, prestigeTier: 5, using: &generator
            )
            XCTAssertGreaterThan(outcome.awayLoyaltyDelta, 0, "Loyalty should increase whether or not the ticket was won")
            XCTAssertEqual(outcome.newAwayLoyaltyPoints, outcome.awayLoyaltyDelta)
        }
    }

    func testAtGuaranteedThresholdAlwaysSucceeds() {
        let threshold = ProgressionConstants.awayTicketGuaranteedThreshold(forPrestigeTier: 2)
        for seed in 0..<50 {
            var generator = SeededGenerator(seed: UInt64(seed))
            let outcome = AwayTicketAllocationEngine.resolve(
                currentAwayLoyaltyPoints: threshold, prestigeTier: 2, using: &generator
            )
            XCTAssertTrue(outcome.gotTicket)
        }
    }

    func testSameSeedIsDeterministic() {
        var generatorA = SeededGenerator(seed: 99)
        var generatorB = SeededGenerator(seed: 99)
        let outcomeA = AwayTicketAllocationEngine.resolve(currentAwayLoyaltyPoints: 10, prestigeTier: 4, using: &generatorA)
        let outcomeB = AwayTicketAllocationEngine.resolve(currentAwayLoyaltyPoints: 10, prestigeTier: 4, using: &generatorB)
        XCTAssertEqual(outcomeA.gotTicket, outcomeB.gotTicket)
        XCTAssertEqual(outcomeA.newAwayLoyaltyPoints, outcomeB.newAwayLoyaltyPoints)
    }
}
