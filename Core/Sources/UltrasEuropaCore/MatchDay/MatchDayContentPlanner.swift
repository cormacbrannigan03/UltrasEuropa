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

    /// The regular length of a match, for pacing a live watch.
    public static let matchLengthMinutes = 90

    /// A deterministic minute-by-minute breakdown of `matchId`'s already-fixed
    /// final score, for pacing watching a match "live" (see
    /// `MatchDayCutsceneView`) — always exactly `homeGoals` home-side events
    /// and `awayGoals` away-side events at distinct minutes, sorted, and the
    /// same every time for the same match. Never changes the actual result —
    /// `homeGoals`/`awayGoals` should come straight from the match's already
    /// generated `homeScore`/`awayScore`.
    public static func goalEvents(matchId: String, homeGoals: Int, awayGoals: Int) -> [GoalEvent] {
        let totalGoals = homeGoals + awayGoals
        guard totalGoals > 0 else { return [] }

        let minutes = shuffledOrder(Array(1...matchLengthMinutes), seed: "\(matchId)-goal-minutes")
            .prefix(totalGoals)
            .sorted()
        let sides = shuffledOrder(
            Array(repeating: true, count: homeGoals) + Array(repeating: false, count: awayGoals),
            seed: "\(matchId)-goal-sides"
        )

        return zip(minutes, sides).enumerated().map { index, pair in
            let scorerName = MatchPlayerNames.name(seed: "\(matchId)-goal-\(index)-scorer")
            return GoalEvent(id: "\(matchId)-goal-\(index)", minute: pair.0, isHomeTeam: pair.1, scorerName: scorerName)
        }
    }

    /// A deterministic set of 0-4 cards shown during `matchId`'s live-watch
    /// breakdown — same seeded-hash technique as `goalEvents`, entirely
    /// independent of the score. Roughly 1 in 10 cards is a red.
    public static func cardEvents(matchId: String) -> [CardEvent] {
        let countHash = SeasonScheduleGenerator.hashSeed("\(matchId)-card-count")
        let count = Int(countHash % 5) // 0...4
        guard count > 0 else { return [] }

        let minutes = shuffledOrder(Array(1...matchLengthMinutes), seed: "\(matchId)-card-minutes")
            .prefix(count)
            .sorted()

        return minutes.enumerated().map { index, minute in
            let baseSeed = "\(matchId)-card-\(index)"
            let isHomeTeam = SeasonScheduleGenerator.hashSeed("\(baseSeed)-side") % 2 == 0
            let isRed = SeasonScheduleGenerator.hashSeed("\(baseSeed)-red") % 10 == 0
            let playerName = MatchPlayerNames.name(seed: "\(baseSeed)-player")
            return CardEvent(
                id: "\(matchId)-card-\(index)",
                minute: minute,
                isHomeTeam: isHomeTeam,
                playerName: playerName,
                isRed: isRed
            )
        }
    }

    /// A deterministic, random-feeling set of mid-match stance check-in
    /// minutes for `matchId` — stable per match, but not on a predictable
    /// fixed grid, so check-ins don't always land on the same beats every
    /// match. Always includes the final minute (full time) so the "sustained
    /// the whole match" stance reward stays well-defined; `count` more
    /// minutes are drawn from the rest of the match at random.
    public static func stanceCheckpointMinutes(matchId: String, count: Int = 5) -> [Int] {
        let candidateMinutes = Array(1..<matchLengthMinutes)
        let picked = shuffledOrder(candidateMinutes, seed: "\(matchId)-stance-checkpoints")
            .prefix(count)
            .sorted()
        return picked + [matchLengthMinutes]
    }

    /// A deterministic Fisher-Yates shuffle of `array`, seeded off `seed` —
    /// not cryptographic, just stable across launches for the same seed.
    private static func shuffledOrder<T>(_ array: [T], seed: String) -> [T] {
        var result = array
        guard result.count > 1 else { return result }

        var state = SeasonScheduleGenerator.hashSeed(seed)
        for i in stride(from: result.count - 1, through: 1, by: -1) {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            let j = Int(state % UInt64(i + 1))
            result.swapAt(i, j)
        }
        return result
    }
}
