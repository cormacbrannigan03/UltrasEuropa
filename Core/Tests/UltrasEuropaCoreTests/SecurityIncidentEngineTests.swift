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

    // MARK: - Probabilistic resolve

    func testEjectionChanceIsZeroBelowThreshold() {
        XCTAssertEqual(SecurityIncidentEngine.ejectionChance(forHeat: SecurityIncidentEngine.ejectionThreshold - 1), 0)
    }

    func testEjectionChanceNeverReachesCertainty() {
        XCTAssertLessThan(SecurityIncidentEngine.ejectionChance(forHeat: 1000), 1.0)
    }

    func testBanChanceIsZeroBelowThreshold() {
        XCTAssertEqual(SecurityIncidentEngine.banChance(forHeat: SecurityIncidentEngine.banThreshold - 1), 0)
    }

    func testBanChanceNeverReachesCertainty() {
        XCTAssertLessThan(SecurityIncidentEngine.banChance(forHeat: 1000), 1.0)
    }

    func testResolveNeverEjectsBelowEjectionThreshold() {
        for seed in 0..<50 {
            var generator = SeededGenerator(seed: UInt64(seed))
            let outcome = SecurityIncidentEngine.resolve(forHeat: SecurityIncidentEngine.ejectionThreshold - 1, using: &generator)
            XCTAssertNotEqual(outcome, .ejected)
            XCTAssertNotEqual(outcome, .ejectedWithBan(days: SecurityIncidentEngine.banDurationDays))
        }
    }

    func testResolveIsDeterministicForTheSameSeed() {
        var generatorA = SeededGenerator(seed: 42)
        var generatorB = SeededGenerator(seed: 42)
        let heat = ReactionSeverity.extreme.heat
        let resultA = SecurityIncidentEngine.resolve(forHeat: heat, using: &generatorA)
        let resultB = SecurityIncidentEngine.resolve(forHeat: heat, using: &generatorB)
        XCTAssertEqual(resultA, resultB)
    }

    func testResolveCanBothEjectAndSpareAcrossSeeds() {
        var sawEjection = false
        var sawWarnedOnly = false
        let heat = ReactionSeverity.extreme.heat
        for seed in 0..<200 {
            var generator = SeededGenerator(seed: UInt64(seed))
            switch SecurityIncidentEngine.resolve(forHeat: heat, using: &generator) {
            case .ejected, .ejectedWithBan: sawEjection = true
            case .warned: sawWarnedOnly = true
            case .noAction: break
            }
        }
        XCTAssertTrue(sawEjection, "A single Extreme reaction's heat should still be able to eject")
        XCTAssertTrue(sawWarnedOnly, "...but should no longer guarantee it every time")
    }

    func testResolveNeverExceedsWhatOutcomeWouldAllow() {
        // resolve() should never produce a result more severe than the
        // deterministic outcome(forHeat:) reference point would.
        for heat in stride(from: 0, through: 120, by: 5) {
            for seed in 0..<10 {
                var generator = SeededGenerator(seed: UInt64(seed))
                let resolved = SecurityIncidentEngine.resolve(forHeat: heat, using: &generator)
                let ceiling = SecurityIncidentEngine.outcome(forHeat: heat)
                XCTAssertLessThanOrEqual(severityRank(resolved), severityRank(ceiling))
            }
        }
    }

    private func severityRank(_ outcome: SecurityOutcome) -> Int {
        switch outcome {
        case .noAction: return 0
        case .warned: return 1
        case .ejected: return 2
        case .ejectedWithBan: return 3
        }
    }
}
