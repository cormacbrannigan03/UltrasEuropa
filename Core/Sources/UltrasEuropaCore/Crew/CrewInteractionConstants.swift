import Foundation

/// Balance + flavor text for every `CrewInteractionType`. Change numbers
/// here to retune without touching `CrewInteractionEngine`.
public enum CrewInteractionConstants {

    public struct Config: Sendable {
        public let successChance: Double
        public let successRange: ClosedRange<Int>
        public let failureRange: ClosedRange<Int>

        public init(successChance: Double, successRange: ClosedRange<Int>, failureRange: ClosedRange<Int>) {
            self.successChance = successChance
            self.successRange = successRange
            self.failureRange = failureRange
        }
    }

    public static let configs: [CrewInteractionType: Config] = [
        .chat: Config(successChance: 0.80, successRange: 2...6, failureRange: 1...3),
        .inviteToMatch: Config(successChance: 0.65, successRange: 5...12, failureRange: 3...8),
        .shareAChant: Config(successChance: 0.70, successRange: 4...10, failureRange: 2...6),
        .standUpForThem: Config(successChance: 0.55, successRange: 10...20, failureRange: 8...15),
        .teaseThem: Config(successChance: 0.50, successRange: 3...8, failureRange: 4...10),
    ]

    public static func config(for interaction: CrewInteractionType) -> Config {
        configs[interaction] ?? Config(successChance: 0.7, successRange: 1...5, failureRange: 1...5)
    }

    /// Bond score is clamped to this range.
    public static let bondRange = -100...100

    /// The highest bond score a crew member ranked above the player will
    /// allow — kept inside `RelationshipLevel.stranger`, short of
    /// `.acquaintance` (bond 20) — until the player has proven themselves
    /// enough to be worth their time. See `acknowledges(memberRank:playerRank:)`.
    public static let unacknowledgedBondCeiling = 15

    /// Whether a crew member ranked `memberRank` will treat the player as
    /// more than a passing stranger yet. Regular/Young Ultra-tier members
    /// are peers and always will. A member ranked Ultra Group or above —
    /// the "top ultras" — needs the player to have already reached the
    /// rank just below their own first; a Capo-tier member won't take a
    /// newcomer seriously until the player is themselves a Lead Ultra.
    public static func acknowledges(memberRank: Rank, playerRank: Rank) -> Bool {
        guard let requiredRank = Rank(rawValue: memberRank.rawValue - 1) else { return true }
        return playerRank >= requiredRank
    }

    public static func unacknowledgedMessage(memberName: String, memberRank: Rank) -> String {
        "\(memberName) barely gives you the time of day. As a \(memberRank.displayName), they're not interested in a newcomer who hasn't proven themselves further up the ladder yet."
    }

    public static func message(for interaction: CrewInteractionType, memberName: String, didGoWell: Bool) -> String {
        switch interaction {
        case .chat:
            return didGoWell
                ? "You and \(memberName) talked for ages about the last away day."
                : "The conversation with \(memberName) fizzled out awkwardly."
        case .inviteToMatch:
            return didGoWell
                ? "\(memberName) had a great time at the match with you."
                : "\(memberName) couldn't make it and seemed put out about it."
        case .shareAChant:
            return didGoWell
                ? "\(memberName) loved the chant you taught them."
                : "\(memberName) wasn't impressed by your chant."
        case .standUpForThem:
            return didGoWell
                ? "\(memberName) won't forget that you had their back."
                : "\(memberName) felt you handled it badly."
        case .teaseThem:
            return didGoWell
                ? "\(memberName) laughed along with the joke."
                : "\(memberName) didn't find that funny at all."
        }
    }
}
