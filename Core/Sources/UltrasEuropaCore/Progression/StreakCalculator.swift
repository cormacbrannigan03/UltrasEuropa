import Foundation

public struct StreakEvaluation: Sendable, Equatable {
    public let newStreakDays: Int
    public let shouldRecordDailyCheckIn: Bool
}

/// Decides how a character's day-streak changes when the app is opened,
/// and whether that counts as a new daily loyalty check-in (which awards
/// its own small activity reward — see `ProgressionConstants`).
public enum StreakCalculator {

    public static func evaluate(
        lastActiveDate: Date?,
        currentStreakDays: Int,
        today: Date,
        calendar: Calendar = .current
    ) -> StreakEvaluation {
        guard let lastActiveDate else {
            // First time ever opening the app with an active character.
            return StreakEvaluation(newStreakDays: 1, shouldRecordDailyCheckIn: true)
        }

        if calendar.isDate(lastActiveDate, inSameDayAs: today) {
            // Already checked in today — no change, no repeat reward.
            return StreakEvaluation(newStreakDays: currentStreakDays, shouldRecordDailyCheckIn: false)
        }

        guard let dayAfterLastActive = calendar.date(byAdding: .day, value: 1, to: lastActiveDate) else {
            return StreakEvaluation(newStreakDays: 1, shouldRecordDailyCheckIn: true)
        }

        if calendar.isDate(dayAfterLastActive, inSameDayAs: today) {
            // Consecutive day — streak continues.
            return StreakEvaluation(newStreakDays: currentStreakDays + 1, shouldRecordDailyCheckIn: true)
        }

        // Missed one or more days — streak resets.
        return StreakEvaluation(newStreakDays: 1, shouldRecordDailyCheckIn: true)
    }
}
