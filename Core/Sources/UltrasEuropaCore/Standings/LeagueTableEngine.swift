import Foundation

/// Computes a league table purely from a list of matches — the same
/// generated-on-demand fixtures `SeasonScheduleGenerator` already produces,
/// so there's nothing new to store: the table is just a summary of
/// whichever of those fixtures have already been played.
public enum LeagueTableEngine {
    /// Standings for every club in `clubIds`, sorted by points, then goal
    /// difference, then goals scored — the standard football table order —
    /// falling back to club id so the order is always fully deterministic.
    /// Unplayed fixtures, and fixtures involving a club not in `clubIds`,
    /// are ignored.
    public static func standings(matches: [Match], clubIds: [String]) -> [LeagueTableRow] {
        var rowsByClubId: [String: LeagueTableRow] = Dictionary(
            uniqueKeysWithValues: clubIds.map { ($0, LeagueTableRow(clubId: $0)) }
        )

        for match in matches {
            guard match.isPlayed, let homeScore = match.homeScore, let awayScore = match.awayScore else { continue }
            guard var home = rowsByClubId[match.homeClubId], var away = rowsByClubId[match.awayClubId] else { continue }

            home.played += 1
            away.played += 1
            home.goalsFor += homeScore
            home.goalsAgainst += awayScore
            away.goalsFor += awayScore
            away.goalsAgainst += homeScore

            if homeScore > awayScore {
                home.won += 1
                away.lost += 1
            } else if homeScore < awayScore {
                away.won += 1
                home.lost += 1
            } else {
                home.drawn += 1
                away.drawn += 1
            }

            rowsByClubId[match.homeClubId] = home
            rowsByClubId[match.awayClubId] = away
        }

        return rowsByClubId.values.sorted { lhs, rhs in
            if lhs.points != rhs.points { return lhs.points > rhs.points }
            if lhs.goalDifference != rhs.goalDifference { return lhs.goalDifference > rhs.goalDifference }
            if lhs.goalsFor != rhs.goalsFor { return lhs.goalsFor > rhs.goalsFor }
            return lhs.clubId < rhs.clubId
        }
    }
}
