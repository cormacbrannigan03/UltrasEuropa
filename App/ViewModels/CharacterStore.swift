import Foundation
import SwiftData
import Observation
import UltrasEuropaCore

/// Summary of what a single activity (or the daily check-in) produced, so a
/// view can show a rank-up celebration or "you unlocked X" toast.
struct ActivityOutcomeSummary: Equatable {
    let xpAwarded: Int
    let previousRank: Rank
    let newRank: Rank
    let newlyUnlockedAchievements: [Achievement]
    let newlyUnlockedItems: [InventoryItem]

    var didRankUp: Bool { newRank > previousRank }

    static func == (lhs: ActivityOutcomeSummary, rhs: ActivityOutcomeSummary) -> Bool {
        lhs.xpAwarded == rhs.xpAwarded
            && lhs.previousRank == rhs.previousRank
            && lhs.newRank == rhs.newRank
            && lhs.newlyUnlockedAchievements.map(\.id) == rhs.newlyUnlockedAchievements.map(\.id)
            && lhs.newlyUnlockedItems.map(\.id) == rhs.newlyUnlockedItems.map(\.id)
    }
}

/// The single owner of character state: creation, every progression-earning
/// action, and the read-only derived values (rank, stats, next-rank
/// progress, owned items) views bind to. Wraps SwiftData persistence around
/// the pure `UltrasEuropaCore` progression engine — this class is the only
/// place those two layers meet.
@Observable
final class CharacterStore {
    private let modelContext: ModelContext
    private let content: ContentRepository

    private(set) var character: CharacterEntity?

    /// The outcome of the most recently applied activity, for the UI to
    /// present (rank-up banner, unlock toast) and then clear.
    var lastOutcome: ActivityOutcomeSummary?

    init(modelContext: ModelContext, content: ContentRepository) {
        self.modelContext = modelContext
        self.content = content
        self.character = try? modelContext.fetch(FetchDescriptor<CharacterEntity>()).first
    }

    var hasCharacter: Bool { character != nil }

    // MARK: - Character creation

    func createCharacter(name: String, favoriteClubId: String, today: Date = .now) {
        let entity = CharacterEntity(name: name, favoriteClubId: favoriteClubId, createdAt: today, lastActiveDate: today)
        modelContext.insert(entity)
        character = entity
        try? modelContext.save()
        // Starts the streak at day 1 without granting a duplicate check-in
        // reward on the very first app open.
        entity.currentStreakDays = 1
        try? modelContext.save()
    }

    // MARK: - Daily loyalty streak

    /// Call once when the app becomes active. Advances (or resets) the
    /// streak and, on a new day, grants the passive daily check-in reward.
    func refreshDailyStreak(today: Date = .now, calendar: Calendar = .current) {
        guard let character else { return }
        let evaluation = StreakCalculator.evaluate(
            lastActiveDate: character.lastActiveDate,
            currentStreakDays: character.currentStreakDays,
            today: today,
            calendar: calendar
        )
        character.currentStreakDays = evaluation.newStreakDays
        character.lastActiveDate = today

        if evaluation.shouldRecordDailyCheckIn {
            apply(activity: .dailyLoyaltyCheckIn, matchId: nil, satInUltrasStand: false, didPyro: false, today: today, calendar: calendar)
        } else {
            try? modelContext.save()
        }
    }

    // MARK: - Recording activities

    @discardableResult
    func recordActivity(
        _ activity: ActivityType,
        matchId: String? = nil,
        satInUltrasStand: Bool = false,
        didPyro: Bool = false,
        today: Date = .now,
        calendar: Calendar = .current
    ) -> ActivityOutcomeSummary? {
        apply(activity: activity, matchId: matchId, satInUltrasStand: satInUltrasStand, didPyro: didPyro, today: today, calendar: calendar)
    }

    func completeTask(_ taskId: String) {
        guard let character, !isTaskCompleted(taskId) else { return }
        let completion = CompletedTaskEntity(taskId: taskId)
        completion.character = character
        modelContext.insert(completion)
        character.completedTasks.append(completion)
        recordActivity(.completeTask)
    }

    func isTaskCompleted(_ taskId: String) -> Bool {
        character?.completedTasks.contains { $0.taskId == taskId } ?? false
    }

    func hasAttended(matchId: String) -> Bool {
        character?.attendanceLog.contains { $0.matchId == matchId } ?? false
    }

    // MARK: - Derived, read-only state

    var stats: CharacterStats {
        character.map(PersistenceMapper.stats(from:)) ?? .initial
    }

    var rank: Rank {
        character.map(PersistenceMapper.rank(from:)) ?? .regular
    }

    var unlockedAchievementIDs: Set<String> {
        character.map(PersistenceMapper.unlockedAchievementIDs(from:)) ?? []
    }

    var lifetimeActivityCounts: [ActivityType: Int] {
        character.map(PersistenceMapper.lifetimeActivityCounts(from:)) ?? [:]
    }

    var ownedItemIDs: Set<String> {
        Set(character?.ownedItems.map(\.itemId) ?? [])
    }

    var unlockedAchievements: [Achievement] {
        content.achievementCatalog.filter { unlockedAchievementIDs.contains($0.id) }
    }

    var ownedItems: [InventoryItem] {
        content.inventoryCatalog.filter { ownedItemIDs.contains($0.id) }
    }

    var nextRankProgress: RankProgress? {
        RankCalculator.nextRankProgress(
            current: rank,
            stats: stats,
            activityCounts: lifetimeActivityCounts,
            unlockedAchievementIDs: unlockedAchievementIDs
        )
    }

    // MARK: - Private

    @discardableResult
    private func apply(
        activity: ActivityType,
        matchId: String?,
        satInUltrasStand: Bool,
        didPyro: Bool,
        today: Date,
        calendar: Calendar
    ) -> ActivityOutcomeSummary? {
        guard let character else { return nil }

        let statsBefore = PersistenceMapper.stats(from: character)
        let countsBefore = PersistenceMapper.lifetimeActivityCounts(from: character)
        let unlockedBefore = PersistenceMapper.unlockedAchievementIDs(from: character)
        let occurrenceIndex = PersistenceMapper.todayOccurrenceIndex(
            for: activity, on: character, today: today, calendar: calendar
        )

        let outcome = ProgressionEngine.apply(
            activity: activity,
            occurrenceIndexToday: occurrenceIndex,
            currentStats: statsBefore,
            activityCounts: countsBefore,
            unlockedAchievementIDs: unlockedBefore
        )

        PersistenceMapper.apply(outcome.updatedStats, to: character)
        PersistenceMapper.setRank(outcome.newRank, on: character)

        let log = ActivityLogEntity(activityTypeRaw: activity.rawValue, timestamp: today, xpAwarded: outcome.xpAwarded)
        log.character = character
        modelContext.insert(log)
        character.activityLog.append(log)

        if activity == .attendMatch, let matchId {
            let attendance = MatchAttendanceEntity(
                matchId: matchId, dateAttended: today,
                satInUltrasStand: satInUltrasStand, didPyro: didPyro
            )
            attendance.character = character
            modelContext.insert(attendance)
            character.attendanceLog.append(attendance)
        }

        let countsAfter = PersistenceMapper.lifetimeActivityCounts(from: character)

        let newlyUnlockedAchievements = AchievementEvaluator.newlyUnlocked(
            catalog: content.achievementCatalog,
            stats: outcome.updatedStats,
            activityCounts: countsAfter,
            currentRank: outcome.newRank,
            alreadyUnlockedIDs: unlockedBefore
        )
        for achievement in newlyUnlockedAchievements {
            let unlock = UnlockedAchievementEntity(achievementId: achievement.id)
            unlock.character = character
            modelContext.insert(unlock)
            character.unlockedAchievements.append(unlock)
        }

        let ownedBefore = Set(character.ownedItems.map(\.itemId))
        let newlyUnlockedItems = content.inventoryCatalog.filter { item in
            guard !ownedBefore.contains(item.id) else { return false }
            return AchievementEvaluator.isSatisfied(
                item.unlockCriteria,
                stats: outcome.updatedStats,
                activityCounts: countsAfter,
                currentRank: outcome.newRank
            )
        }
        for item in newlyUnlockedItems {
            let owned = OwnedItemEntity(itemId: item.id)
            owned.character = character
            modelContext.insert(owned)
            character.ownedItems.append(owned)
        }

        try? modelContext.save()

        let summary = ActivityOutcomeSummary(
            xpAwarded: outcome.xpAwarded,
            previousRank: outcome.previousRank,
            newRank: outcome.newRank,
            newlyUnlockedAchievements: newlyUnlockedAchievements,
            newlyUnlockedItems: newlyUnlockedItems
        )
        lastOutcome = summary
        return summary
    }
}
