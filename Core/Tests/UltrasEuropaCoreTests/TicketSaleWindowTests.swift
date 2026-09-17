import XCTest
@testable import UltrasEuropaCore

final class TicketSaleWindowTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    func testSaleDateIsThirtyDaysBeforeMatch() {
        let matchDate = date(2026, 6, 30)
        let saleDate = TicketSaleWindow.saleDate(matchDate: matchDate, calendar: calendar)
        XCTAssertEqual(saleDate, date(2026, 5, 31))
    }

    func testNotOnSaleBeforeSaleDate() {
        let matchDate = date(2026, 6, 30)
        let today = date(2026, 5, 30)
        XCTAssertFalse(TicketSaleWindow.isOnSale(matchDate: matchDate, asOf: today, calendar: calendar))
    }

    func testOnSaleExactlyAtSaleDate() {
        let matchDate = date(2026, 6, 30)
        let today = date(2026, 5, 31)
        XCTAssertTrue(TicketSaleWindow.isOnSale(matchDate: matchDate, asOf: today, calendar: calendar))
    }

    func testOnSaleAfterSaleDate() {
        let matchDate = date(2026, 6, 30)
        let today = date(2026, 6, 15)
        XCTAssertTrue(TicketSaleWindow.isOnSale(matchDate: matchDate, asOf: today, calendar: calendar))
    }

    func testOnSaleOnMatchDayItself() {
        let matchDate = date(2026, 6, 30)
        XCTAssertTrue(TicketSaleWindow.isOnSale(matchDate: matchDate, asOf: matchDate, calendar: calendar))
    }
}
