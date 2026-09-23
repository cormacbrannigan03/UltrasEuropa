import Foundation

/// How the player spends the live-watch beat's full 90 minutes — chosen
/// once at kickoff rather than only reacting at goals, and re-confirmable
/// at each 15-minute checkpoint (see `MatchDayCutsceneView`) so a stance
/// can be dropped partway through — e.g. easing off if the favorite club
/// is losing — rather than being a single irreversible commitment.
public enum MatchStance: String, CaseIterable, Codable, Hashable, Sendable {
    case singNonStop
    case watchQuietly
    case windUpRivals
    case filmForSocials

    public var displayName: String {
        switch self {
        case .singNonStop: return "Sing Non-Stop"
        case .watchQuietly: return "Watch Quietly"
        case .windUpRivals: return "Wind Up the Away End"
        case .filmForSocials: return "Film for Socials"
        }
    }

    public var selectionDescription: String {
        switch self {
        case .singNonStop: return "Keep the songs going for the full 90 minutes."
        case .watchQuietly: return "Take it all in without making a scene."
        case .windUpRivals: return "Give the away end constant stick — security won't love it."
        case .filmForSocials: return "Capture the whole match for the crew's socials."
        }
    }

    /// Heat added to `SecurityIncidentEngine`'s running total at every
    /// checkpoint this stance is kept up — `0` for the two low-key
    /// stances, so keeping either of the more demonstrative ones going
    /// the whole match is a real, visible risk, not just flavor.
    public var heatPerCheckpoint: Int {
        switch self {
        case .singNonStop, .watchQuietly: return 0
        case .windUpRivals: return 8
        case .filmForSocials: return 2
        }
    }

    /// The activity recorded once, at full time, for keeping this stance
    /// up the entire match without easing off early — see
    /// `ProgressionConstants.activityRewards`. Nothing is recorded if the
    /// player stops before full time.
    public var activityType: ActivityType {
        switch self {
        case .singNonStop: return .sustainSingNonStop
        case .watchQuietly: return .sustainWatchQuietly
        case .windUpRivals: return .sustainWindUpRivals
        case .filmForSocials: return .sustainFilmForSocials
        }
    }
}
