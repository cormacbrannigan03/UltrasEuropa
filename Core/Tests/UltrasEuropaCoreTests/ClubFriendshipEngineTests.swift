import XCTest
@testable import UltrasEuropaCore

final class ClubFriendshipEngineTests: XCTestCase {

    func testSameLeagueIsEasierThanDifferentLeague() {
        let sameLeague = ClubFriendshipEngine.chance(playerRank: .regular, sameLeague: true)
        let differentLeague = ClubFriendshipEngine.chance(playerRank: .regular, sameLeague: false)
        XCTAssertGreaterThan(sameLeague, differentLeague)
    }

    func testHigherRankIncreasesChance() {
        var previous = ClubFriendshipEngine.chance(playerRank: .regular, sameLeague: false)
        for rank in Rank.allCases.dropFirst() {
            let chance = ClubFriendshipEngine.chance(playerRank: rank, sameLeague: false)
            XCTAssertGreaterThanOrEqual(chance, previous)
            previous = chance
        }
    }

    func testChanceIsClampedBetweenFiveAndNinetyFivePercent() {
        for rank in Rank.allCases {
            for sameLeague in [true, false] {
                let chance = ClubFriendshipEngine.chance(playerRank: rank, sameLeague: sameLeague)
                XCTAssertGreaterThanOrEqual(chance, 0.05)
                XCTAssertLessThanOrEqual(chance, 0.95)
            }
        }
    }

    func testResolveIsDeterministicForTheSameSeed() {
        var generatorA = SeededGenerator(seed: 33)
        var generatorB = SeededGenerator(seed: 33)
        let resultA = ClubFriendshipEngine.resolve(playerRank: .youngUltra, sameLeague: true, using: &generatorA)
        let resultB = ClubFriendshipEngine.resolve(playerRank: .youngUltra, sameLeague: true, using: &generatorB)
        XCTAssertEqual(resultA, resultB)
    }

    func testResolveCanBothAcceptAndDeclineAcrossSeeds() {
        var sawAccepted = false
        var sawDeclined = false
        for seed in 0..<200 {
            var generator = SeededGenerator(seed: UInt64(seed))
            if ClubFriendshipEngine.resolve(playerRank: .regular, sameLeague: false, using: &generator) {
                sawAccepted = true
            } else {
                sawDeclined = true
            }
        }
        XCTAssertTrue(sawAccepted)
        XCTAssertTrue(sawDeclined)
    }
}
