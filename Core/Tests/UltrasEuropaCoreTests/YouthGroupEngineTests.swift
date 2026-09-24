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

    // MARK: - Unprompted join requests

    func testJoinRequestChanceIncreasesAsGroupGrows() {
        let early = YouthGroupEngine.joinRequestChance(currentMembers: 1)
        let mid = YouthGroupEngine.joinRequestChance(currentMembers: 20)
        let late = YouthGroupEngine.joinRequestChance(currentMembers: 60)
        XCTAssertLessThan(early, mid)
        XCTAssertLessThan(mid, late)
    }

    func testJoinRequestChanceNeverExceedsCap() {
        let chance = YouthGroupEngine.joinRequestChance(currentMembers: 10_000)
        XCTAssertLessThanOrEqual(chance, 0.25)
    }

    func testJoinRequestChanceOppositeTrendFromRecruitChance() {
        // The whole point of the mechanic: recruiting gets *harder* as the
        // group grows, but unprompted requests get *more* likely.
        let recruitEarly = YouthGroupEngine.recruitChance(currentMembers: 0)
        let recruitLate = YouthGroupEngine.recruitChance(currentMembers: 40)
        let joinEarly = YouthGroupEngine.joinRequestChance(currentMembers: 0)
        let joinLate = YouthGroupEngine.joinRequestChance(currentMembers: 40)
        XCTAssertGreaterThan(recruitEarly, recruitLate)
        XCTAssertLessThan(joinEarly, joinLate)
    }

    func testResolveJoinRequestAppearsIsDeterministicForTheSameSeed() {
        var generatorA = SeededGenerator(seed: 21)
        var generatorB = SeededGenerator(seed: 21)
        let resultA = YouthGroupEngine.resolveJoinRequestAppears(currentMembers: 12, using: &generatorA)
        let resultB = YouthGroupEngine.resolveJoinRequestAppears(currentMembers: 12, using: &generatorB)
        XCTAssertEqual(resultA, resultB)
    }

    func testResolveJoinRequestAppearsCanBothHappenAndNotAcrossSeeds() {
        var sawAppearance = false
        var sawNoAppearance = false
        for seed in 0..<300 {
            var generator = SeededGenerator(seed: UInt64(seed))
            if YouthGroupEngine.resolveJoinRequestAppears(currentMembers: 20, using: &generator) {
                sawAppearance = true
            } else {
                sawNoAppearance = true
            }
        }
        XCTAssertTrue(sawAppearance)
        XCTAssertTrue(sawNoAppearance)
    }
}
