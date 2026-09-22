import Foundation

/// The result of one interaction: whether it went well, how much the bond
/// score changed, and flavor text describing what happened.
public struct CrewInteractionOutcome: Sendable {
    public let didGoWell: Bool
    public let bondDelta: Int
    public let message: String
}

/// Resolves a single interaction with a crew member into an outcome and
/// the member's new (clamped) bond score. Pure and testable: takes an
/// injected `RandomNumberGenerator` so tests can seed a deterministic
/// sequence, while real gameplay uses `SystemRandomNumberGenerator`.
public enum CrewInteractionEngine {
    /// - Parameters:
    ///   - memberRank: this crew member's own rank tier — see
    ///     `CrewInteractionConstants.acknowledges(memberRank:playerRank:)`.
    ///     Defaults to `.regular` (always acknowledges) so existing callers
    ///     that don't care about the gate are unaffected.
    ///   - playerRank: the interacting character's current rank. Defaults
    ///     to `.regular`; only matters when `memberRank` is above it.
    public static func resolve<G: RandomNumberGenerator>(
        interaction: CrewInteractionType,
        memberName: String,
        memberRank: Rank = .regular,
        playerRank: Rank = .regular,
        currentBond: Int,
        using generator: inout G
    ) -> (outcome: CrewInteractionOutcome, newBond: Int) {
        let bondRange = CrewInteractionConstants.bondRange

        guard CrewInteractionConstants.acknowledges(memberRank: memberRank, playerRank: playerRank) else {
            let ceiling = CrewInteractionConstants.unacknowledgedBondCeiling
            let newBond = max(bondRange.lowerBound, min(ceiling, currentBond))
            let outcome = CrewInteractionOutcome(
                didGoWell: false,
                bondDelta: 0,
                message: CrewInteractionConstants.unacknowledgedMessage(memberName: memberName, memberRank: memberRank)
            )
            return (outcome, newBond)
        }

        let config = CrewInteractionConstants.config(for: interaction)
        let didGoWell = Double.random(in: 0..<1, using: &generator) < config.successChance
        let bondDelta = didGoWell
            ? Int.random(in: config.successRange, using: &generator)
            : -Int.random(in: config.failureRange, using: &generator)

        let newBond = max(bondRange.lowerBound, min(bondRange.upperBound, currentBond + bondDelta))

        let outcome = CrewInteractionOutcome(
            didGoWell: didGoWell,
            bondDelta: bondDelta,
            message: CrewInteractionConstants.message(for: interaction, memberName: memberName, didGoWell: didGoWell)
        )
        return (outcome, newBond)
    }
}
