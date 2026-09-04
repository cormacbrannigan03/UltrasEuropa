import XCTest
@testable import UltrasEuropaCore

final class ProgressionEngineTests: XCTestCase {

    func testAppliesBaseRewardOnFirstOccurrenceToday() {
        let outcome = ProgressionEngine.apply(
            activity: .attendMatch,
            occurrenceIndexToday: 1,
            currentStats: .initial,
            activityCounts: [:],
            unlockedAchievementIDs: []
        )
        XCTAssertEqual(outcome.xpAwarded, 50)
        XCTAssertEqual(outcome.updatedStats.loyalty, 4)
        XCTAssertEqual(outcome.updatedStats.matchesAttended, 1)
        XCTAssertEqual(outcome.updatedStats.totalXP, 50)
    }

    func testDiminishingReturnsReduceLaterSameDayRewards() {
        let first = ProgressionEngine.apply(
            activity: .participateInChant, occurrenceIndexToday: 1,
            currentStats: .initial, activityCounts: [:], unlockedAchievementIDs: []
        )
        let third = ProgressionEngine.apply(
            activity: .participateInChant, occurrenceIndexToday: 3,
            currentStats: .initial, activityCounts: [:], unlockedAchievementIDs: []
        )
        let tenth = ProgressionEngine.apply(
            activity: .participateInChant, occurrenceIndexToday: 10,
            currentStats: .initial, activityCounts: [:], unlockedAchievementIDs: []
        )

        XCTAssertEqual(first.xpAwarded, 20, "First two occurrences per day should be full reward")
        XCTAssertLessThan(third.xpAwarded, first.xpAwarded, "Third same-day occurrence should start decaying")
        XCTAssertLessThan(tenth.xpAwarded, third.xpAwarded, "Reward should keep shrinking with repetition")
        XCTAssertGreaterThan(tenth.xpAwarded, 0, "Reward should never hit zero (floor applies)")
    }

    func testRepeatingOneActivityAllDayCannotMatchVariedActivity() {
        // Simulate grinding the SAME activity 20 times in a day vs. doing
        // 5 different activities 4 times each. Total occurrence count is
        // equal (20), but the grind path should yield meaningfully less
        // total XP once diminishing returns kick in.
        var grindXP = 0
        for occurrence in 1...20 {
            grindXP += ProgressionEngine.apply(
                activity: .completeTask, occurrenceIndexToday: occurrence,
                currentStats: .initial, activityCounts: [:], unlockedAchievementIDs: []
            ).xpAwarded
        }

        var variedXP = 0
        let activities: [ActivityType] = [.attendMatch, .sitInUltrasStand, .doPyroChallenge, .participateInChant, .completeTask]
        for activity in activities {
            for occurrence in 1...4 {
                variedXP += ProgressionEngine.apply(
                    activity: activity, occurrenceIndexToday: occurrence,
                    currentStats: .initial, activityCounts: [:], unlockedAchievementIDs: []
                ).xpAwarded
            }
        }

        // completeTask base is 25; grinding 20x at that base would be 500
        // without decay. With decay it must be substantially less.
        XCTAssertLessThan(grindXP, 25 * 20)
        // Sanity: varied play across higher-value activities comfortably
        // out-earns pure grinding of a single mid-value activity.
        XCTAssertGreaterThan(variedXP, grindXP)
    }

    func testRankUpIsDetected() {
        var stats = CharacterStats.initial
        stats.totalXP = 299
        stats.matchesAttended = 4

        let outcome = ProgressionEngine.apply(
            activity: .attendMatch,
            occurrenceIndexToday: 1,
            currentStats: stats,
            activityCounts: [.attendMatch: 4],
            unlockedAchievementIDs: []
        )

        XCTAssertEqual(outcome.previousRank, .regular)
        XCTAssertEqual(outcome.newRank, .youngUltra)
        XCTAssertTrue(outcome.didRankUp)
    }

    func testNoRankUpWhenThresholdNotYetMet() {
        let outcome = ProgressionEngine.apply(
            activity: .completeTask,
            occurrenceIndexToday: 1,
            currentStats: .initial,
            activityCounts: [:],
            unlockedAchievementIDs: []
        )
        XCTAssertFalse(outcome.didRankUp)
        XCTAssertEqual(outcome.newRank, .regular)
    }
}
