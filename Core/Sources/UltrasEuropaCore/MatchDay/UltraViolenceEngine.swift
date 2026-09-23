import Foundation

/// How the player gets involved in a pre-match confrontation with a rival
/// firm — see `UltraViolenceEngine`.
public enum UltraViolenceRole: String, Codable, Hashable, Sendable {
    /// Organizing/instigating it outright — only available to senior,
    /// established members (see `UltraViolenceEngine.minimumRankToInstigate`),
    /// since it takes standing in the group to call the shots. Organized
    /// firms plan around the police, so this carries a *lower* chance of
    /// police intervention than just wading in.
    case instigator
    /// Piling in on something already kicking off — open to anyone,
    /// regardless of rank, but with no control over the situation and no
    /// planning around the police, so it's *more* likely to end in police
    /// intervention than instigating it.
    case participant
}

/// What happened once the confrontation resolved.
public enum UltraViolenceOutcome: Equatable, Sendable {
    case gotAway
    case policeIntervention(banDays: Int)
}

/// Resolves a pre-match confrontation with a rival firm — deliberately
/// kept abstract (a resolved outcome plus consequences, not a blow-by-blow
/// account): whether the player gets away with it, or police step in and
/// eject/ban them. Risk scales with both the fixture's `MatchCategory`
/// (heavier police presence at bigger games) and the player's `role`.
public enum UltraViolenceEngine {
    /// The minimum rank to be allowed to instigate (see `.instigator`) —
    /// starting something is a leadership call, not something a rank file
    /// member can just decide to do.
    public static let minimumRankToInstigate = Rank.leadUltra

    /// How many days a police-issued ban lasts — longer than a stadium
    /// ejection's ban (`SecurityIncidentEngine.banDurationDays`), since
    /// this is a police matter, not just being thrown out by stewards.
    public static let policeBanDurationDays = 30

    /// Base chance (0...1) of police intervention for `role`, before the
    /// fixture's category is factored in.
    private static let baseInterventionChance: [UltraViolenceRole: Double] = [
        .instigator: 0.20,
        .participant: 0.40,
    ]

    /// How much heavier policing at a bigger fixture raises that base
    /// chance — added on top, not multiplied, so it stays meaningful even
    /// for the already-higher participant base.
    private static let categoryInterventionBump: [MatchCategory: Double] = [
        .one: 0.25,
        .two: 0.10,
        .three: 0.0,
    ]

    public static func interventionChance(role: UltraViolenceRole, category: MatchCategory) -> Double {
        let base = baseInterventionChance[role] ?? 0.4
        let bump = categoryInterventionBump[category] ?? 0.0
        return min(0.95, max(0.05, base + bump))
    }

    public static func resolve<G: RandomNumberGenerator>(
        role: UltraViolenceRole, category: MatchCategory, using generator: inout G
    ) -> UltraViolenceOutcome {
        let caught = Double.random(in: 0..<1, using: &generator) < interventionChance(role: role, category: category)
        return caught ? .policeIntervention(banDays: policeBanDurationDays) : .gotAway
    }
}
