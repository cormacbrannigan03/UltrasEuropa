import XCTest
@testable import UltrasEuropaCore

final class SecurityIncidentEngineTests: XCTestCase {

    func testNoActionBelowWarningThreshold() {
        XCTAssertEqual(SecurityIncidentEngine.outcome(forHeat: 0), .noAction)
        XCTAssertEqual(SecurityIncidentEngine.outcome(forHeat: SecurityIncidentEngine.warningThreshold - 1), .noAction)
    }

    func testWarnedAtThreshold() {
        XCTAssertEqual(SecurityIncidentEngine.outcome(forHeat: SecurityIncidentEngine.warningThreshold), .warned)
    }

    func testEjectedAtThreshold() {
        XCTAssertEqual(SecurityIncidentEngine.outcome(forHeat: SecurityIncidentEngine.ejectionThreshold), .ejected)
    }

    func testEjectedWithBanAtThreshold() {
        XCTAssertEqual(
            SecurityIncidentEngine.outcome(forHeat: SecurityIncidentEngine.banThreshold),
            .ejectedWithBan(days: SecurityIncidentEngine.banDurationDays)
        )
    }

    func testThresholdsAreStrictlyIncreasing() {
        XCTAssertLessThan(SecurityIncidentEngine.warningThreshold, SecurityIncidentEngine.ejectionThreshold)
        XCTAssertLessThan(SecurityIncidentEngine.ejectionThreshold, SecurityIncidentEngine.banThreshold)
    }

    func testReactionSeverityHeatIncreasesWithSeverity() {
        let heats = ReactionSeverity.allCases.sorted { $0.rawValue < $1.rawValue }.map(\.heat)
        XCTAssertEqual(heats, heats.sorted())
    }

    func testFourMildReactionsNeverTriggerAnything() {
        let heat = Array(repeating: ReactionSeverity.mild, count: 4).reduce(0) { $0 + $1.heat }
        XCTAssertEqual(SecurityIncidentEngine.outcome(forHeat: heat), .noAction)
    }

    func testOneExtremeReactionTriggersEjection() {
        XCTAssertEqual(SecurityIncidentEngine.outcome(forHeat: ReactionSeverity.extreme.heat), .ejected)
    }

    func testTwoExtremeReactionsTriggerABan() {
        let heat = ReactionSeverity.extreme.heat * 2
        XCTAssertEqual(
            SecurityIncidentEngine.outcome(forHeat: heat),
            .ejectedWithBan(days: SecurityIncidentEngine.banDurationDays)
        )
    }

    func testEachReactionSeverityMapsToItsOwnActivityType() {
        XCTAssertEqual(ReactionSeverity.mild.activityType, .reactMildly)
        XCTAssertEqual(ReactionSeverity.moderate.activityType, .reactModerately)
        XCTAssertEqual(ReactionSeverity.strong.activityType, .reactStrongly)
        XCTAssertEqual(ReactionSeverity.extreme.activityType, .reactExtremely)
    }
}
