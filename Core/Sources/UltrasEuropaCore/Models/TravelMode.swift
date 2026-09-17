import Foundation

/// How the player travels to an away game — a flavor choice with a small,
/// real effect (see `ProgressionConstants.busTravelAwayLoyaltyBonus`):
/// the bus is the more communal, old-school ultras way and builds a little
/// extra away loyalty; the train is just the practical, neutral option.
public enum TravelMode: String, CaseIterable, Hashable, Sendable {
    case bus
    case train

    public var displayName: String {
        switch self {
        case .bus: return "Bus"
        case .train: return "Train"
        }
    }

    /// A deterministic "preference" for a given crew member, so the game
    /// can show flavor lines like "Tommy thinks the bus is more fun"
    /// consistently rather than randomly each time.
    public static func preferred(byMemberId memberId: String) -> TravelMode {
        let scalarSum = memberId.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return scalarSum % 2 == 0 ? .bus : .train
    }
}
