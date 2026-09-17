import Foundation

/// The result of one attempt to get an away ticket.
public struct AwayTicketOutcome: Sendable {
    public let gotTicket: Bool
    public let awayLoyaltyDelta: Int
    public let newAwayLoyaltyPoints: Int
    public let chanceWas: Double
}

/// Resolves whether a single away-ticket request succeeds. Away tickets are
/// never simply granted: the chance rises with accumulated away loyalty
/// points (see `ProgressionConstants.awayTicketChance`) until it reaches a
/// guarantee, but a bad roll still nudges loyalty up a little so a run of
/// bad luck isn't a dead end. Pure and testable via an injected
/// `RandomNumberGenerator`, same pattern as `CrewInteractionEngine`.
public enum AwayTicketAllocationEngine {
    public static func resolve<G: RandomNumberGenerator>(
        currentAwayLoyaltyPoints: Int,
        prestigeTier: Int,
        using generator: inout G
    ) -> AwayTicketOutcome {
        let chance = ProgressionConstants.awayTicketChance(
            awayLoyaltyPoints: currentAwayLoyaltyPoints, prestigeTier: prestigeTier
        )
        let gotTicket = Double.random(in: 0..<1, using: &generator) < chance
        let delta = gotTicket
            ? ProgressionConstants.awayTicketSuccessLoyaltyGain
            : ProgressionConstants.awayTicketConsolationLoyaltyGain

        return AwayTicketOutcome(
            gotTicket: gotTicket,
            awayLoyaltyDelta: delta,
            newAwayLoyaltyPoints: currentAwayLoyaltyPoints + delta,
            chanceWas: chance
        )
    }
}
