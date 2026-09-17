import Foundation

/// When tickets for a match actually go on sale — real clubs don't sell
/// tickets for a game months out, so neither should this one. Tickets open
/// a fixed window before kickoff, regardless of home/away/neutral context.
public enum TicketSaleWindow {
    public static let daysBeforeMatch = 30

    /// The date tickets for `matchDate` go on sale.
    public static func saleDate(matchDate: Date, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: -daysBeforeMatch, to: matchDate) ?? matchDate
    }

    /// Whether tickets for `matchDate` are on sale as of `today`.
    public static func isOnSale(matchDate: Date, asOf today: Date, calendar: Calendar = .current) -> Bool {
        today >= saleDate(matchDate: matchDate, calendar: calendar)
    }
}
