import Foundation

/// Resolves whether another club's ultras group accepts a friendship
/// proposal from the player's own crew — see
/// `CharacterStore.proposeClubFriendship`. Deterministic-over-random
/// where it can be: the chance is visible and driven by things the player
/// actually controls (their own standing, and picking a club in the same
/// league), not a flat hidden coin flip.
public enum ClubFriendshipEngine {
    /// Chance of acceptance for a Regular-rank player proposing to a club
    /// outside their own league.
    public static let baseAcceptanceChance = 0.55
    /// Clubs in the same league are easier to coordinate away days and
    /// meetups with, so a same-league proposal lands more often.
    public static let sameLeagueBonus = 0.2
    /// Standing in your own crew makes another club's ultras take a
    /// proposal more seriously — a small bump per rank above Regular.
    public static let perRankBonus = 0.05

    public static func chance(playerRank: Rank, sameLeague: Bool) -> Double {
        let rankBonus = Double(playerRank.rawValue) * perRankBonus
        let leagueBonus = sameLeague ? sameLeagueBonus : 0
        return min(0.95, max(0.05, baseAcceptanceChance + rankBonus + leagueBonus))
    }

    public static func resolve<G: RandomNumberGenerator>(
        playerRank: Rank, sameLeague: Bool, using generator: inout G
    ) -> Bool {
        Double.random(in: 0..<1, using: &generator) < chance(playerRank: playerRank, sameLeague: sameLeague)
    }
}
