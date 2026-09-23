import Foundation

/// Every discrete action the player can take that grants progression.
public enum ActivityType: String, Codable, CaseIterable, Hashable, Sendable {
    case attendMatch
    case sitInUltrasStand
    case doPyroChallenge
    case participateInChant
    case contributeToTifo
    case completeTask
    case dailyLoyaltyCheckIn
    /// Recorded automatically whenever the player interacts with a
    /// `CrewMember` (see `CrewInteractionEngine`) — deliberately excluded
    /// from `ProgressionConstants.coreDiversityActivityTypes` so it's a
    /// bonus, not a required gate, on top of the existing rank ladder.
    case socializeWithCrew
    /// Recorded when the player launches a clothing range (Capo-only, see
    /// `CharacterStore.launchClothingRange`). Also excluded from the
    /// diversity gate — same reasoning as `socializeWithCrew`.
    case launchClothingRange
    /// Reacting to a goal during the match-day live-watch beat, at one of
    /// four severities (see `ReactionSeverity`) — each is its own activity
    /// type rather than one activity with an intensity parameter, so each
    /// can carry its own fixed reward. All four are excluded from the
    /// diversity gate, same reasoning as `socializeWithCrew`.
    case reactMildly
    case reactModerately
    case reactStrongly
    case reactExtremely
    /// Founding, and later recruiting into, the player's own breakaway
    /// youth group — see `YouthGroupEngine`. Excluded from the diversity
    /// gate, same reasoning as `socializeWithCrew`: a bonus system, not a
    /// required part of the core rank ladder.
    case foundYouthGroup
    case recruitYouthGroupMember
    /// The two mutually-exclusive endings once the youth group grows large
    /// enough to rival the main ultras group — see
    /// `CharacterStore.mergeYouthGroupWithMainUltras`/`takeOverMainUltrasGroup`.
    case mergeYouthGroup
    case takeOverUltrasGroup
    /// Getting involved in a pre-match confrontation with a rival firm —
    /// see `UltraViolenceEngine`. Excluded from the diversity gate, same
    /// reasoning as `socializeWithCrew`: a risky bonus path, not a
    /// required part of the core rank ladder.
    case startUltraViolence
    case joinUltraViolence
    /// Proposing, and later collaborating with, another club's ultras
    /// group once a friendship is accepted — see `ClubFriendshipEngine`
    /// and `CharacterStore.proposeClubFriendship`/`collaborateWithFriendClub`.
    /// Excluded from the diversity gate, same reasoning as `socializeWithCrew`.
    case proposeClubFriendship
    case collaborateWithFriendClub
    /// Recorded alongside `attendMatch` whenever the match being attended
    /// involves a friend club (either side) — showing up for a friendly
    /// group's game, not just your own. Also excluded from the diversity
    /// gate.
    case attendFriendClubMatch
    /// Recorded once, at full time, for keeping a `MatchStance` up the
    /// entire live-watch beat without easing off early — see
    /// `MatchStance.activityType`. Excluded from the diversity gate, same
    /// reasoning as `socializeWithCrew`.
    case sustainSingNonStop
    case sustainWatchQuietly
    case sustainWindUpRivals
    case sustainFilmForSocials
}
