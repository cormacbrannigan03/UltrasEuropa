import XCTest
@testable import UltrasEuropaCore

final class HomeSeatRequestEngineTests: XCTestCase {

    func testUltrasSectionIsHarderThanEverySection() {
        let ultrasChance = HomeSeatRequestEngine.chance(
            for: .ultrasSection, prestigeTier: 3, hasUltrasSeasonTicket: false
        )
        for seat in SeatCategory.allCases where seat != .ultrasSection {
            let otherChance = HomeSeatRequestEngine.chance(for: seat, prestigeTier: 3, hasUltrasSeasonTicket: false)
            XCTAssertLessThan(ultrasChance, otherChance, "\(seat) should be easier than the Ultras Section")
        }
    }

    func testSeasonTicketHolderIsGuaranteedUltrasSection() {
        let chance = HomeSeatRequestEngine.chance(for: .ultrasSection, prestigeTier: 5, hasUltrasSeasonTicket: true)
        XCTAssertEqual(chance, 1.0)
    }

    func testHigherPrestigeTierMakesEverySectionHarder() {
        for seat in SeatCategory.allCases {
            let smallClubChance = HomeSeatRequestEngine.chance(for: seat, prestigeTier: 1, hasUltrasSeasonTicket: false)
            let giantClubChance = HomeSeatRequestEngine.chance(for: seat, prestigeTier: 5, hasUltrasSeasonTicket: false)
            XCTAssertGreaterThan(smallClubChance, giantClubChance)
        }
    }

    func testChanceIsClampedBetweenFiveAndHundredPercent() {
        for seat in SeatCategory.allCases {
            for tier in 1...5 {
                let chance = HomeSeatRequestEngine.chance(for: seat, prestigeTier: tier, hasUltrasSeasonTicket: false)
                XCTAssertGreaterThanOrEqual(chance, 0.05)
                XCTAssertLessThanOrEqual(chance, 1.0)
            }
        }
    }

    func testResolveIsDeterministicForTheSameSeed() {
        var generatorA = SeededGenerator(seed: 55)
        var generatorB = SeededGenerator(seed: 55)
        let resultA = HomeSeatRequestEngine.resolve(
            seat: .ultrasSection, prestigeTier: 3, hasUltrasSeasonTicket: false, using: &generatorA
        )
        let resultB = HomeSeatRequestEngine.resolve(
            seat: .ultrasSection, prestigeTier: 3, hasUltrasSeasonTicket: false, using: &generatorB
        )
        XCTAssertEqual(resultA, resultB)
    }

    func testResolveCanBothSucceedAndFailAcrossSeeds() {
        var sawSuccess = false
        var sawFailure = false
        for seed in 0..<200 {
            var generator = SeededGenerator(seed: UInt64(seed))
            let result = HomeSeatRequestEngine.resolve(
                seat: .ultrasSection, prestigeTier: 3, hasUltrasSeasonTicket: false, using: &generator
            )
            if result { sawSuccess = true } else { sawFailure = true }
        }
        XCTAssertTrue(sawSuccess)
        XCTAssertTrue(sawFailure)
    }
}
