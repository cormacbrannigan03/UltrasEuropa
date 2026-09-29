import XCTest
@testable import UltrasEuropaCore

final class TicketDemandEngineTests: XCTestCase {

    // MARK: - Form

    func testFormMultiplierIsNeutralAtLeagueAverage() {
        let multiplier = TicketDemandEngine.formMultiplier(recentPointsPerGame: TicketDemandEngine.neutralPointsPerGame)
        XCTAssertEqual(multiplier, 1.0, accuracy: 0.0001)
    }

    func testFormMultiplierLowersDemandForAHotStreak() {
        let hot = TicketDemandEngine.formMultiplier(recentPointsPerGame: 3.0)
        XCTAssertLessThan(hot, 1.0)
    }

    func testFormMultiplierRaisesDemandForAColdStreak() {
        let cold = TicketDemandEngine.formMultiplier(recentPointsPerGame: 0.0)
        XCTAssertGreaterThan(cold, 1.0)
    }

    func testFormMultiplierClampsOutOfRangeInput() {
        let aboveMax = TicketDemandEngine.formMultiplier(recentPointsPerGame: 10)
        let belowMin = TicketDemandEngine.formMultiplier(recentPointsPerGame: -5)
        XCTAssertEqual(aboveMax, TicketDemandEngine.formMultiplier(recentPointsPerGame: 3.0), accuracy: 0.0001)
        XCTAssertEqual(belowMin, TicketDemandEngine.formMultiplier(recentPointsPerGame: 0.0), accuracy: 0.0001)
    }

    // MARK: - Standing

    func testStandingMultiplierLowersDemandForTopOfTable() {
        let top = TicketDemandEngine.standingMultiplier(position: 1, leagueSize: 20)
        XCTAssertLessThan(top, 1.0)
    }

    func testStandingMultiplierRaisesDemandForBottomOfTable() {
        let bottom = TicketDemandEngine.standingMultiplier(position: 20, leagueSize: 20)
        XCTAssertGreaterThan(bottom, 1.0)
    }

    func testStandingMultiplierIsNeutralForASingleClubLeague() {
        XCTAssertEqual(TicketDemandEngine.standingMultiplier(position: 1, leagueSize: 1), 1.0, accuracy: 0.0001)
    }

    func testStandingMultiplierMonotonicallyIncreasesWithPosition() {
        let leagueSize = 20
        var previous = TicketDemandEngine.standingMultiplier(position: 1, leagueSize: leagueSize)
        for position in 2...leagueSize {
            let current = TicketDemandEngine.standingMultiplier(position: position, leagueSize: leagueSize)
            XCTAssertGreaterThan(current, previous)
            previous = current
        }
    }

    // MARK: - Combined

    func testCombinedMultiplierStaysWithinClampedRange() {
        XCTAssertEqual(
            TicketDemandEngine.combinedMultiplier(recentPointsPerGame: 3.0, position: 1, leagueSize: 20),
            0.8, accuracy: 0.0001
        )
        XCTAssertEqual(
            TicketDemandEngine.combinedMultiplier(recentPointsPerGame: 0.0, position: 20, leagueSize: 20),
            1.2, accuracy: 0.0001
        )
    }

    func testCombinedMultiplierIsNeutralForAverageFormAndMidTable() {
        let multiplier = TicketDemandEngine.combinedMultiplier(
            recentPointsPerGame: TicketDemandEngine.neutralPointsPerGame, position: 10, leagueSize: 19
        )
        XCTAssertEqual(multiplier, 1.0, accuracy: 0.02)
    }

    // MARK: - Adjusted chance

    func testAdjustedChanceAppliesMultiplier() {
        XCTAssertEqual(TicketDemandEngine.adjustedChance(baseChance: 0.5, multiplier: 1.2), 0.6, accuracy: 0.0001)
    }

    func testAdjustedChanceNeverExceedsOne() {
        XCTAssertEqual(TicketDemandEngine.adjustedChance(baseChance: 0.9, multiplier: 1.2), 1.0, accuracy: 0.0001)
    }

    func testAdjustedChanceNeverGoesBelowFloor() {
        XCTAssertEqual(TicketDemandEngine.adjustedChance(baseChance: 0.02, multiplier: 0.8), 0.05, accuracy: 0.0001)
    }
}
