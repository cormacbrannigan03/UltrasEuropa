import Foundation

/// Generates a full double round-robin domestic season (every club plays
/// every other club home and away) for a league, entirely on the fly.
///
/// With ~20 leagues and up to 20 clubs each, a full season is thousands of
/// fixtures — far too much to hand-author or ship as static JSON, and there
/// is no real fixture list to source for a game. So the schedule (dates,
/// pairings, and placeholder results for already-played rounds) is derived
/// deterministically from the club list and today's date every time the
/// app loads, rather than stored anywhere. Because it's seeded off stable
/// inputs (league/club ids), the same inputs always produce the same
/// schedule and results — nothing changes between app launches just from
/// recomputing it.
///
/// Results for past fixtures are synthetic, not real — clearly a game
/// placeholder, not a claim about real-world results.
public enum SeasonScheduleGenerator {

    /// The full season schedule for one league: every pairing played twice
    /// (home and away), dated across a season starting the most recent
    /// August 1st on or before `today`, with a synthetic score on any
    /// fixture whose date has already passed.
    public static func generateSeason(
        league: League,
        clubs: [Club],
        today: Date,
        calendar: Calendar = .current
    ) -> [Match] {
        guard clubs.count >= 2 else { return [] }

        let seasonStart = defaultSeasonStartDate(today: today, calendar: calendar)
        let firstHalf = singleRoundRobinRounds(teamCount: clubs.count)
        let secondHalf = firstHalf.map { round in round.map { (home: $0.away, away: $0.home) } }

        var matches: [Match] = []
        var currentDate = seasonStart

        for (halfIndex, half) in [firstHalf, secondHalf].enumerated() {
            if halfIndex == 1 {
                // A short midseason gap so the reverse fixtures don't land
                // immediately after the first half ends.
                currentDate = calendar.date(byAdding: .day, value: 21, to: currentDate) ?? currentDate
            }
            for round in half {
                for pairing in round {
                    let home = clubs[pairing.home]
                    let away = clubs[pairing.away]
                    let matchId = "\(league.id)-\(home.id)-\(away.id)"
                    let isPlayed = currentDate <= today
                    let score = isPlayed ? deterministicScore(seed: matchId) : nil

                    matches.append(Match(
                        id: matchId,
                        homeClubId: home.id,
                        awayClubId: away.id,
                        date: currentDate,
                        competition: league.name,
                        venue: home.stadiumName,
                        homeScore: score?.home,
                        awayScore: score?.away
                    ))
                }
                currentDate = calendar.date(byAdding: .day, value: 7, to: currentDate) ?? currentDate
            }
        }

        return matches
    }

    /// The most recent August 1st on or before `today` — European domestic
    /// seasons run roughly August through May.
    public static func defaultSeasonStartDate(today: Date, calendar: Calendar = .current) -> Date {
        let year = calendar.component(.year, from: today)
        let month = calendar.component(.month, from: today)
        let seasonYear = month >= 7 ? year : year - 1
        return calendar.date(from: DateComponents(year: seasonYear, month: 8, day: 1)) ?? today
    }

    // MARK: - Round-robin pairing (circle method)

    /// One single round-robin (each team plays every other team once) as a
    /// sequence of rounds, each a list of (home index, away index) pairings
    /// into the `clubs` array passed to `generateSeason`. Odd team counts
    /// get an unpaired "bye" each round, simply producing one fewer match
    /// that round.
    static func singleRoundRobinRounds(teamCount: Int) -> [[(home: Int, away: Int)]] {
        var indices = Array(0..<teamCount)
        let byeIndex = -1
        if indices.count % 2 != 0 {
            indices.append(byeIndex)
        }
        let n = indices.count
        guard n >= 2 else { return [] }

        var rounds: [[(home: Int, away: Int)]] = []
        var arr = indices

        for round in 0..<(n - 1) {
            var pairings: [(home: Int, away: Int)] = []
            for i in 0..<(n / 2) {
                let a = arr[i]
                let b = arr[n - 1 - i]
                guard a != byeIndex, b != byeIndex else { continue }
                // Alternate which side is "home" round-to-round for a more
                // even home/away split across the rotation.
                pairings.append(round % 2 == 0 ? (home: a, away: b) : (home: b, away: a))
            }
            rounds.append(pairings)

            // Rotate: keep index 0 fixed, cycle everyone else.
            let last = arr.removeLast()
            arr.insert(last, at: 1)
        }

        return rounds
    }

    // MARK: - Deterministic synthetic scores

    /// A stable (not cryptographic) FNV-1a hash, used only to seed
    /// `deterministicScore` so the same match id always yields the same
    /// placeholder result.
    static func hashSeed(_ string: String) -> UInt64 {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1_099_511_628_211
        }
        return hash
    }

    /// Deterministically derives a plausible-looking (not real) scoreline
    /// from a seed string, with a slight home-side bias.
    static func deterministicScore(seed: String) -> (home: Int, away: Int) {
        var z = hashSeed(seed) &+ 0x9E37_79B9_7F4A_7C15
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        z = z ^ (z >> 31)

        let home = Int(z % 5)
        let away = Int((z >> 16) % 4)
        return (home: home, away: away)
    }
}
