import XCTest
@testable import UltrasEuropaCore

final class StreakCalculatorTests: XCTestCase {

    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        utcCalendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    func testFirstEverCheckInStartsStreakAtOne() {
        let result = StreakCalculator.evaluate(
            lastActiveDate: nil, currentStreakDays: 0,
            today: date(2026, 1, 1), calendar: utcCalendar
        )
        XCTAssertEqual(result.newStreakDays, 1)
        XCTAssertTrue(result.shouldRecordDailyCheckIn)
    }

    func testSameDayReopenDoesNotChangeStreakOrDoubleReward() {
        let result = StreakCalculator.evaluate(
            lastActiveDate: date(2026, 1, 1), currentStreakDays: 5,
            today: date(2026, 1, 1), calendar: utcCalendar
        )
        XCTAssertEqual(result.newStreakDays, 5)
        XCTAssertFalse(result.shouldRecordDailyCheckIn)
    }

    func testConsecutiveDayIncrementsStreak() {
        let result = StreakCalculator.evaluate(
            lastActiveDate: date(2026, 1, 1), currentStreakDays: 5,
            today: date(2026, 1, 2), calendar: utcCalendar
        )
        XCTAssertEqual(result.newStreakDays, 6)
        XCTAssertTrue(result.shouldRecordDailyCheckIn)
    }

    func testGapResetsStreakToOne() {
        let result = StreakCalculator.evaluate(
            lastActiveDate: date(2026, 1, 1), currentStreakDays: 5,
            today: date(2026, 1, 4), calendar: utcCalendar
        )
        XCTAssertEqual(result.newStreakDays, 1)
        XCTAssertTrue(result.shouldRecordDailyCheckIn)
    }
}
