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
    public static func resolve<G: RandomNumberGenerator>(
        interaction: CrewInteractionType,
        memberName: String,
        currentBond: Int,
        using generator: inout G
    ) -> (outcome: CrewInteractionOutcome, newBond: Int) {
        let config = CrewInteractionConstants.config(for: interaction)
        let didGoWell = Double.random(in: 0..<1, using: &generator) < config.successChance
        let bondDelta = didGoWell
            ? Int.random(in: config.successRange, using: &generator)
            : -Int.random(in: config.failureRange, using: &generator)

        let bondRange = CrewInteractionConstants.bondRange
        let newBond = max(bondRange.lowerBound, min(bondRange.upperBound, currentBond + bondDelta))

        let outcome = CrewInteractionOutcome(
            didGoWell: didGoWell,
            bondDelta: bondDelta,
            message: CrewInteractionConstants.message(for: interaction, memberName: memberName, didGoWell: didGoWell)
        )
        return (outcome, newBond)
    }
}
