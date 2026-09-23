import Foundation

/// A pool of clearly-generic, fictional player names used for goal scorers
/// and card recipients (see `GoalEvent.scorerName` and
/// `CardEvent.playerName`). Deliberately not real footballers — the same
/// honesty policy already applied to invented crew, chants, and tifo
/// content: real clubs and leagues are used, but nothing here claims to be
/// a real person. Internal to the package — nothing outside `MatchDay`
/// needs to pick a name directly.
enum MatchPlayerNames {
    static let pool: [String] = [
        "J. Marsh", "D. Okafor", "L. Novak", "R. Fontaine", "T. Bergqvist",
        "M. Alesci", "K. Haddad", "S. Lindqvist", "A. Rousseau", "P. Vintner",
        "C. Delgado", "N. Osei", "F. Kowalski", "E. Brandt", "H. Duclos",
        "V. Marchetti", "O. Ibsen", "G. Salinas", "W. Ferreira", "B. Lucchese",
        "I. Kastanov", "Y. Berisha", "Z. Moreau", "Q. Teixeira", "U. Sandberg",
        "X. Almeida", "R. Kowalczyk", "D. Pavicic", "L. Sorensen", "M. Traore",
    ]

    /// A stable name from the pool for `seed`.
    static func name(seed: String) -> String {
        let hash = SeasonScheduleGenerator.hashSeed(seed)
        return pool[Int(hash % UInt64(pool.count))]
    }
}
