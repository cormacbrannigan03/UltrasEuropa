import Foundation

/// Resolves the pre-match security search for a player carrying pyro —
/// pure and testable via an injected `RandomNumberGenerator`, same pattern
/// as `AwayTicketAllocationEngine`.
public enum SecurityCheckEngine {
    /// Whether pyro hidden in `spot` gets past the search. `true` means it
    /// got through; `false` means it's confiscated at the gate.
    public static func resolvePyroSearch<G: RandomNumberGenerator>(
        spot: PyroHidingSpot, using generator: inout G
    ) -> Bool {
        Double.random(in: 0..<1, using: &generator) < spot.searchSuccessChance
    }
}
