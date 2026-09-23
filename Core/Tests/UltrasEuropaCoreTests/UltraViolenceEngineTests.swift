import XCTest
@testable import UltrasEuropaCore

final class UltraViolenceEngineTests: XCTestCase {

    func testParticipantIsRiskierThanInstigatorAtEveryCategory() {
        for category in MatchCategory.allCases {
            let instigatorChance = UltraViolenceEngine.interventionChance(role: .instigator, category: category)
            let participantChance = UltraViolenceEngine.interventionChance(role: .participant, category: category)
            XCTAssertLessThan(
                instigatorChance, participantChance,
                "Instigating (organized, rank-gated) should be safer than just piling in, at \(category)"
            )
        }
    }

    func testHigherCategoryIsRiskierForBothRoles() {
        for role in [UltraViolenceRole.instigator, .participant] {
            let categoryOneChance = UltraViolenceEngine.interventionChance(role: role, category: .one)
            let categoryTwoChance = UltraViolenceEngine.interventionChance(role: role, category: .two)
            let categoryThreeChance = UltraViolenceEngine.interventionChance(role: role, category: .three)
            XCTAssertGreaterThan(categoryOneChance, categoryTwoChance)
            XCTAssertGreaterThan(categoryTwoChance, categoryThreeChance)
        }
    }

    func testInterventionChanceIsClampedBetweenFiveAndNinetyFivePercent() {
        for role in [UltraViolenceRole.instigator, .participant] {
            for category in MatchCategory.allCases {
                let chance = UltraViolenceEngine.interventionChance(role: role, category: category)
                XCTAssertGreaterThanOrEqual(chance, 0.05)
                XCTAssertLessThanOrEqual(chance, 0.95)
            }
        }
    }

    func testResolveIsDeterministicForTheSameSeed() {
        var generatorA = SeededGenerator(seed: 77)
        var generatorB = SeededGenerator(seed: 77)
        let resultA = UltraViolenceEngine.resolve(role: .participant, category: .one, using: &generatorA)
        let resultB = UltraViolenceEngine.resolve(role: .participant, category: .one, using: &generatorB)
        XCTAssertEqual(resultA, resultB)
    }

    func testResolveCanBothGetAwayAndBeCaughtAcrossSeeds() {
        var sawGotAway = false
        var sawIntervention = false
        for seed in 0..<200 {
            var generator = SeededGenerator(seed: UInt64(seed))
            switch UltraViolenceEngine.resolve(role: .participant, category: .one, using: &generator) {
            case .gotAway: sawGotAway = true
            case .policeIntervention: sawIntervention = true
            }
        }
        XCTAssertTrue(sawGotAway)
        XCTAssertTrue(sawIntervention)
    }

    func testPoliceInterventionUsesThePoliceBanDuration() {
        // Force a near-certain intervention (Category 1, participant) and
        // confirm the ban length matches the documented constant across a
        // handful of seeds.
        for seed in 0..<20 {
            var generator = SeededGenerator(seed: UInt64(seed))
            if case .policeIntervention(let days) = UltraViolenceEngine.resolve(
                role: .participant, category: .one, using: &generator
            ) {
                XCTAssertEqual(days, UltraViolenceEngine.policeBanDurationDays)
            }
        }
    }
}
