import Foundation

/// Decides what a specific match's crew-participation moments are — which
/// chant gets sung, and whether a tifo display is prepared for it — so the
/// match-day experience is tied to a real fixture instead of a free-floating
/// catalog the player can trigger from anywhere, anytime.
///
/// Both are derived deterministically from the match id (same technique as
/// `SeasonScheduleGenerator.deterministicScore`), so the same match always
/// gets the same chant/tifo assignment across app launches without needing
/// to persist anything.
public enum MatchDayContentPlanner {

    /// Roughly 1 in 4 matches gets a prepared tifo display — tifos are a
    /// occasional, planned production, not something every crew does every
    /// week the way a chant is.
    static let tifoFrequency: UInt64 = 4

    /// Every match has a chant the crew sings — picks a stable index into
    /// the chants catalog. `nil` only if the catalog itself is empty.
    public static func chantIndex(matchId: String, catalogCount: Int) -> Int? {
        guard catalogCount > 0 else { return nil }
        let hash = SeasonScheduleGenerator.hashSeed("\(matchId)-chant")
        return Int(hash % UInt64(catalogCount))
    }

    /// Whether `matchId` has a tifo display prepared at all.
    public static func isTifoPrepared(matchId: String) -> Bool {
        SeasonScheduleGenerator.hashSeed("\(matchId)-tifo") % tifoFrequency == 0
    }

    /// A stable index into the tifo catalog for `matchId`, or `nil` if this
    /// match doesn't have a tifo prepared (see `isTifoPrepared`) or the
    /// catalog is empty.
    public static func tifoIndex(matchId: String, catalogCount: Int) -> Int? {
        guard catalogCount > 0, isTifoPrepared(matchId: matchId) else { return nil }
        let hash = SeasonScheduleGenerator.hashSeed("\(matchId)-tifo")
        return Int(hash % UInt64(catalogCount))
    }
}
