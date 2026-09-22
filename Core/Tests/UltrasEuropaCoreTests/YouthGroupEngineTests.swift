import XCTest
@testable import UltrasEuropaCore

final class YouthGroupEngineTests: XCTestCase {

    func testNotFoundedRegardlessOfMemberCount() {
        XCTAssertEqual(YouthGroupEngine.stage(forMemberCount: 0, founded: false), .notFounded)
        XCTAssertEqual(YouthGroupEngine.stage(forMemberCount: 100, founded: false), .notFounded)
    }

    func testStageThresholds() {
        XCTAssertEqual(YouthGroupEngine.stage(forMemberCount: 1, founded: true), .founded)
        XCTAssertEqual(YouthGroupEngine.stage(forMemberCount: 4, founded: true), .founded)
        XCTAssertEqual(YouthGroupEngine.stage(forMemberCount: 5, founded: true), .smallFollowing)
        XCTAssertEqual(YouthGroupEngine.stage(forMemberCount: 14, founded: true), .smallFollowing)
        XCTAssertEqual(YouthGroupEngine.stage(forMemberCount: 15, founded: true), .growingCrew)
        XCTAssertEqual(YouthGroupEngine.stage(forMemberCount: 29, founded: true), .growingCrew)
        XCTAssertEqual(YouthGroupEngine.stage(forMemberCount: 30, founded: true), .establishedRival)
        XCTAssertEqual(YouthGroupEngine.stage(forMemberCount: 49, founded: true), .establishedRival)
        XCTAssertEqual(YouthGroupEngine.stage(forMemberCount: 50, founded: true), .empireBuilt)
        XCTAssertEqual(YouthGroupEngine.stage(forMemberCount: 500, founded: true), .empireBuilt)
    }

    func testRecruitChanceDecreasesAsGroupGrows() {
        let early = YouthGroupEngine.recruitChance(currentMembers: 0)
        let mid = YouthGroupEngine.recruitChance(currentMembers: 20)
        let late = YouthGroupEngine.recruitChance(currentMembers: 50)
        XCTAssertGreaterThan(early, mid)
        XCTAssertGreaterThan(mid, late)
    }

    func testRecruitChanceNeverGoesBelowFloor() {
        let chance = YouthGroupEngine.recruitChance(currentMembers: 10_000)
        XCTAssertGreaterThanOrEqual(chance, 0.05)
    }

    func testRecruitChanceNeverExceedsThirtyPercent() {
        let chance = YouthGroupEngine.recruitChance(currentMembers: 0)
        XCTAssertLessThanOrEqual(chance, 0.30)
    }

    func testResolveRecruitIsDeterministicForTheSameSeed() {
        var generatorA = SeededGenerator(seed: 12)
        var generatorB = SeededGenerator(seed: 12)
        let resultA = YouthGroupEngine.resolveRecruit(currentMembers: 3, using: &generatorA)
        let resultB = YouthGroupEngine.resolveRecruit(currentMembers: 3, using: &generatorB)
        XCTAssertEqual(resultA, resultB)
    }

    func testResolveRecruitCanBothSucceedAndFailAcrossSeeds() {
        var sawSuccess = false
        var sawFailure = false
        for seed in 0..<300 {
            var generator = SeededGenerator(seed: UInt64(seed))
            if YouthGroupEngine.resolveRecruit(currentMembers: 0, using: &generator) {
                sawSuccess = true
            } else {
                sawFailure = true
            }
        }
        XCTAssertTrue(sawSuccess)
        XCTAssertTrue(sawFailure)
    }

    func testTakeoverThresholdMatchesEmpireBuiltStage() {
        XCTAssertEqual(YouthGroupEngine.memberThresholds[.empireBuilt], YouthGroupEngine.takeoverThreshold)
    }
}
