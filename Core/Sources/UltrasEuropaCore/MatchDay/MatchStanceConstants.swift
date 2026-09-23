import Foundation

/// Flavor lines for the running "diary" `MatchDayCutsceneView` builds up
/// while a `MatchStance` is kept up — one appears at every 15-minute
/// checkpoint the player chooses to keep going, so a full, uninterrupted
/// match produces six lines of texture instead of the live-watch beat
/// only ever stopping for goals.
public enum MatchStanceConstants {
    public static let diaryLines: [MatchStance: [String]] = [
        .singNonStop: [
            "Your voice is already going, but you keep it up anyway.",
            "The whole section picks up the song after you start it.",
            "You lead a chant the away end can't even understand.",
            "Throat's raw, but you're not stopping now.",
            "A steward gives you a look — you just sing louder.",
            "The drummer locks onto your rhythm and the song swells.",
            "You've lost track of which song you're on.",
            "Someone hands you a scarf to wave along with the song.",
            "The whole stand joins in for the big one.",
            "You catch your breath for a second, then start the next one.",
            "A kid nearby is mouthing along, clearly a first-timer.",
            "You improvise a new verse about today's ref.",
            "The song echoes back from the far side of the ground.",
            "Your section drowns out the tannoy announcement completely.",
            "You're hoarse, but the song's still going.",
        ],
        .watchQuietly: [
            "You quietly note the shape the manager's set up in.",
            "You watch the fullback get exposed again and again.",
            "You clock a tactical switch before the pundits would.",
            "You keep score of who's actually working hard out there.",
            "You watch the away section for any trouble brewing.",
            "You take in the ground itself — the stands, the roof, the pitch.",
            "You quietly rate every player out of ten in your head.",
            "You notice the ref's positioning is genuinely poor today.",
            "You spot the substitute warming up before anyone else does.",
            "You watch the game unfold without saying much at all.",
            "You appreciate a bit of skill nobody else seems to notice.",
            "You clock the away fans going unusually quiet.",
            "You take a mental note of a player worth watching next season.",
            "You watch the linesman miss an obvious offside.",
            "You just enjoy being here, no fuss needed.",
        ],
        .windUpRivals: [
            "You give the away end some fresh stick and they don't like it.",
            "A steward starts eyeing your section a bit more closely.",
            "You lead a chant clearly aimed right at the away end.",
            "Someone in the away end shouts back — you just laugh it off.",
            "You're getting right under their skin now.",
            "A gesture from your section gets a real reaction from them.",
            "You keep needling them every time their team gives the ball away.",
            "The tension between the two ends is properly ramping up now.",
            "You catch a police spotter clocking your section.",
            "You wind them up again the second their team concedes.",
            "A steward has a quiet word, but you keep it going anyway.",
            "You lead one more chorus aimed squarely at the away end.",
            "The atmosphere's got a real edge to it now, and you're loving it.",
            "You catch the eye of someone in the away end who looks furious.",
            "Security radios crackle — they're definitely talking about your end.",
        ],
        .filmForSocials: [
            "You get a great angle of the whole stand bouncing.",
            "You catch the goal celebration completely by chance.",
            "You film a quick clip of the atmosphere for the group chat.",
            "You get a close-up of the crew mid-song.",
            "Your phone's nearly out of storage from all the clips.",
            "You catch a steward looking unimpressed on camera.",
            "You film a slow pan across the whole ground.",
            "You get a great shot just as the flares go up nearby.",
            "You're already editing the highlights reel in your head.",
            "You catch a rival fan's reaction on camera and it's priceless.",
            "You film the tunnel walk-out one more time for the archive.",
            "A steward asks you to put the phone away — you get one more clip in first.",
            "You get the whole section in frame for a group shot.",
            "You catch the exact moment the away end goes silent.",
            "You've basically documented the whole match at this point.",
        ],
    ]

    /// A random line for `stance`, avoiding an immediate repeat of
    /// `previous` when there's more than one to choose from.
    public static func randomLine<G: RandomNumberGenerator>(
        for stance: MatchStance, excluding previous: String? = nil, using generator: inout G
    ) -> String {
        let pool = diaryLines[stance] ?? []
        guard !pool.isEmpty else { return "..." }
        guard pool.count > 1, let previous else {
            return pool.randomElement(using: &generator) ?? pool[0]
        }

        var candidate = pool.randomElement(using: &generator) ?? pool[0]
        var attempts = 0
        while candidate == previous && attempts < 10 {
            candidate = pool.randomElement(using: &generator) ?? pool[0]
            attempts += 1
        }
        return candidate
    }
}
