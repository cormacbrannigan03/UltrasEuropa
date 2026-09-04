import XCTest
@testable import UltrasEuropaCore

final class AchievementEvaluatorTests: XCTestCase {

    func testUnlocksActivityCountAchievementOnceThresholdMet() {
        let catalog = [
            Achievement(
                id: "pyro-veteran", name: "Pyro Veteran",
                achievementDescription: "Ran 10 pyro displays.",
                criteria: .activityCount(.doPyroChallenge, 10)
            )
        ]

        let notYet = AchievementEvaluator.newlyUnlocked(
            catalog: catalog, stats: .initial,
            activityCounts: [.doPyroChallenge: 9], currentRank: .regular,
            alreadyUnlockedIDs: []
        )
        XCTAssertTrue(notYet.isEmpty)

        let nowUnlocked = AchievementEvaluator.newlyUnlocked(
            catalog: catalog, stats: .initial,
            activityCounts: [.doPyroChallenge: 10], currentRank: .regular,
            alreadyUnlockedIDs: []
        )
        XCTAssertEqual(nowUnlocked.map(\.id), ["pyro-veteran"])
    }

    func testDoesNotReUnlockAlreadyUnlockedAchievement() {
        let catalog = [
            Achievement(
                id: "die-hard", name: "Die Hard",
                achievementDescription: "30-day streak.",
                criteria: .streakDays(30)
            )
        ]
        var stats = CharacterStats.initial
        stats.currentStreakDays = 45

        let result = AchievementEvaluator.newlyUnlocked(
            catalog: catalog, stats: stats,
            activityCounts: [:], currentRank: .regular,
            alreadyUnlockedIDs: ["die-hard"]
        )
        XCTAssertTrue(result.isEmpty)
    }

    func testReachRankCriteria() {
        let catalog = [
            Achievement(
                id: "capo-reached", name: "The Capo",
                achievementDescription: "Reached Capo.",
                criteria: .reachRank(.capo)
            )
        ]

        let result = AchievementEvaluator.newlyUnlocked(
            catalog: catalog, stats: .initial,
            activityCounts: [:], currentRank: .leadUltra,
            alreadyUnlockedIDs: []
        )
        XCTAssertTrue(result.isEmpty)

        let unlocked = AchievementEvaluator.newlyUnlocked(
            catalog: catalog, stats: .initial,
            activityCounts: [:], currentRank: .capo,
            alreadyUnlockedIDs: []
        )
        XCTAssertEqual(unlocked.map(\.id), ["capo-reached"])
    }
}
