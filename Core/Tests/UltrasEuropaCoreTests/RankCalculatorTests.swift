import XCTest
@testable import UltrasEuropaCore

final class RankCalculatorTests: XCTestCase {

    func testFreshCharacterIsRegular() {
        let rank = RankCalculator.achievableRank(
            stats: .initial,
            activityCounts: [:],
            unlockedAchievementIDs: []
        )
        XCTAssertEqual(rank, .regular)
    }

    func testHighXPAloneDoesNotReachTopRank() {
        // A character with huge XP from repeating ONE activity type should
        // still be capped well below Capo — this is the core "not simple"
        // requirement: XP alone must not be sufficient.
        var stats = CharacterStats.initial
        stats.totalXP = 10_000
        stats.matchesAttended = 0 // never actually attended a match

        let rank = RankCalculator.achievableRank(
            stats: stats,
            activityCounts: [.participateInChant: 500],
            unlockedAchievementIDs: []
        )
        XCTAssertEqual(rank, .regular, "XP without matches/diversity/achievements must not unlock higher ranks")
    }

    func testYoungUltraRequiresMatchesAttended() {
        var stats = CharacterStats.initial
        stats.totalXP = 300
        stats.matchesAttended = 0

        XCTAssertEqual(
            RankCalculator.achievableRank(stats: stats, activityCounts: [:], unlockedAchievementIDs: []),
            .regular
        )

        stats.matchesAttended = 5
        XCTAssertEqual(
            RankCalculator.achievableRank(stats: stats, activityCounts: [:], unlockedAchievementIDs: []),
            .youngUltra
        )
    }

    func testUltraGroupRequiresActivityDiversity() {
        var stats = CharacterStats.initial
        stats.totalXP = 900
        stats.matchesAttended = 15

        let lowDiversityCounts: [ActivityType: Int] = [.attendMatch: 15]
        XCTAssertEqual(
            RankCalculator.achievableRank(stats: stats, activityCounts: lowDiversityCounts, unlockedAchievementIDs: []),
            .youngUltra,
            "Not enough distinct activity types performed"
        )

        let highDiversityCounts: [ActivityType: Int] = [
            .attendMatch: 15, .sitInUltrasStand: 5, .participateInChant: 5, .contributeToTifo: 2,
        ]
        XCTAssertEqual(
            RankCalculator.achievableRank(stats: stats, activityCounts: highDiversityCounts, unlockedAchievementIDs: []),
            .ultraGroup
        )
    }

    func testLeadUltraRequiresPyroVeteranAchievement() {
        var stats = CharacterStats.initial
        stats.totalXP = 2200
        stats.matchesAttended = 30
        let counts: [ActivityType: Int] = [
            .attendMatch: 30, .sitInUltrasStand: 10, .doPyroChallenge: 10,
            .participateInChant: 10, .contributeToTifo: 10, .completeTask: 10,
        ]

        XCTAssertEqual(
            RankCalculator.achievableRank(stats: stats, activityCounts: counts, unlockedAchievementIDs: []),
            .ultraGroup,
            "Missing the required pyro-veteran achievement should cap rank below Lead Ultra"
        )

        XCTAssertEqual(
            RankCalculator.achievableRank(
                stats: stats, activityCounts: counts,
                unlockedAchievementIDs: [ProgressionConstants.GatingAchievementID.pyroVeteran]
            ),
            .leadUltra
        )
    }

    func testCapoRequiresStreakAndMultipleAchievements() {
        var stats = CharacterStats.initial
        stats.totalXP = 4500
        stats.matchesAttended = 50
        stats.currentStreakDays = 10 // below the 30-day requirement
        let counts: [ActivityType: Int] = [
            .attendMatch: 50, .sitInUltrasStand: 20, .doPyroChallenge: 20,
            .participateInChant: 20, .contributeToTifo: 20, .completeTask: 20,
        ]
        let allButOneAchievement: Set<String> = [
            ProgressionConstants.GatingAchievementID.pyroVeteran,
            ProgressionConstants.GatingAchievementID.tifoArtist,
            ProgressionConstants.GatingAchievementID.chantMaster,
        ]

        XCTAssertEqual(
            RankCalculator.achievableRank(stats: stats, activityCounts: counts, unlockedAchievementIDs: allButOneAchievement),
            .leadUltra,
            "Streak too short and die-hard achievement missing — must not reach Capo"
        )

        stats.currentStreakDays = 30
        let allAchievements = allButOneAchievement.union([ProgressionConstants.GatingAchievementID.dieHard])
        XCTAssertEqual(
            RankCalculator.achievableRank(stats: stats, activityCounts: counts, unlockedAchievementIDs: allAchievements),
            .capo
        )
    }

    func testNextRankProgressReportsMissingAchievements() {
        var stats = CharacterStats.initial
        stats.totalXP = 2200
        stats.matchesAttended = 30
        let counts: [ActivityType: Int] = [
            .attendMatch: 30, .sitInUltrasStand: 10, .doPyroChallenge: 10,
            .participateInChant: 10, .contributeToTifo: 10, .completeTask: 10,
        ]

        let progress = RankCalculator.nextRankProgress(
            current: .ultraGroup,
            stats: stats,
            activityCounts: counts,
            unlockedAchievementIDs: []
        )

        XCTAssertEqual(progress?.rank, .leadUltra)
        XCTAssertEqual(progress?.missingAchievementIDs, Set([ProgressionConstants.GatingAchievementID.pyroVeteran]))
        XCTAssertTrue(progress?.isFullySatisfiedExceptAchievements ?? false)
    }

    func testNoNextRankProgressPastCapo() {
        let progress = RankCalculator.nextRankProgress(
            current: .capo,
            stats: .initial,
            activityCounts: [:],
            unlockedAchievementIDs: []
        )
        XCTAssertNil(progress)
    }

    func testHigherClubPrestigeRequiresMoreXPForSameRank() {
        // Same stats, same activity, same achievements — only the fan's
        // club prestige multiplier differs. A fan of a bigger club should
        // NOT be Young Ultra yet on XP that would be enough for a smaller
        // club's fan.
        var stats = CharacterStats.initial
        stats.totalXP = 300 // exactly the base (multiplier 1.0) threshold
        stats.matchesAttended = 5

        let smallClubRank = RankCalculator.achievableRank(
            stats: stats, activityCounts: [:], unlockedAchievementIDs: [],
            xpMultiplier: ProgressionConstants.xpMultiplier(forPrestigeTier: 1)
        )
        XCTAssertEqual(smallClubRank, .youngUltra, "A smaller club's lower multiplier should make 300 XP enough")

        let giantClubRank = RankCalculator.achievableRank(
            stats: stats, activityCounts: [:], unlockedAchievementIDs: [],
            xpMultiplier: ProgressionConstants.xpMultiplier(forPrestigeTier: 5)
        )
        XCTAssertEqual(giantClubRank, .regular, "A giant club's higher multiplier should make 300 XP NOT enough")
    }

    func testNextRankProgressScalesXPNeededByMultiplier() {
        let baseProgress = RankCalculator.nextRankProgress(
            current: .regular, stats: .initial, activityCounts: [:], unlockedAchievementIDs: []
        )
        let giantClubProgress = RankCalculator.nextRankProgress(
            current: .regular, stats: .initial, activityCounts: [:], unlockedAchievementIDs: [],
            xpMultiplier: ProgressionConstants.xpMultiplier(forPrestigeTier: 5)
        )

        XCTAssertEqual(baseProgress?.xpNeeded, 300)
        XCTAssertGreaterThan(giantClubProgress?.xpNeeded ?? 0, baseProgress?.xpNeeded ?? 0)
    }
}
