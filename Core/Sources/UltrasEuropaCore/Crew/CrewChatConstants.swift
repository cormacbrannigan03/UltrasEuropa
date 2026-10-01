import Foundation

/// The crew member's side of a chat-screen conversation — 100 generic
/// replies (20 per `ChatTopic`), picked at random whenever the player
/// brings that topic up. Deliberately generic and shared across every
/// crew member, same reasoning as `CrewInteractionConstants`'s messages:
/// these are fictional NPCs belonging to the player's own crew, not real
/// people, so there's no need for per-member dialogue.
public enum CrewChatConstants {
    public static let responses: [ChatTopic: [String]] = [
        .lastMatch: [
            "Honestly? Backs to the wall stuff, but we got there.",
            "Same old story — dominate for an hour then make it nervy at the end.",
            "That performance deserved more than we got out of it.",
            "I've seen worse, I've seen better. Solid three points though.",
            "Referee had a shocker if you ask me.",
            "Loved the atmosphere, even if the football wasn't pretty.",
            "We were miles off it if I'm honest.",
            "That's the best we've played all season.",
            "Get in! Needed that one.",
            "Bit of a scrappy watch but a win's a win.",
            "The new signing looked sharp out there.",
            "I'll take the result and not think too hard about the performance.",
            "Some of the away fans gave it some voice, fair play to them.",
            "That's the kind of gutsy display that wins you promotions.",
            "Can't believe we conceded from that set piece again.",
            "The manager's tactics finally clicked.",
            "Worth the trip just for that atmosphere.",
            "We should've had a penalty in the first half, no question.",
            "Bit flat if I'm honest, glad it's over.",
            "That's why we do this every week, isn't it.",
        ],
        .upcomingMatch: [
            "Wouldn't miss it for the world.",
            "Already sorted my ticket, mate.",
            "Depends if I can get the day off work.",
            "Course I am — wouldn't be right without you lot there.",
            "Big one this — everyone needs to be there.",
            "Still deciding, might be a late one.",
            "Away day, isn't it? Already planning the trip.",
            "You know I never miss a home game.",
            "I'm in, as long as the trains are running.",
            "Wouldn't want to jinx it by saying yes too early.",
            "That's a nailed-on yes from me.",
            "Gonna try get a group of us down for that one.",
            "If the weather holds up, definitely.",
            "That's the one I've had marked in the calendar for weeks.",
            "Need to check with the missus first, but probably.",
            "Wild horses couldn't keep me away.",
            "Might give this one a miss, saving myself for the derby.",
            "Getting the early train down for that one.",
            "As long as I'm not working, I'm there.",
            "That one's a must, big test for us.",
        ],
        .lifeOutsideFootball: [
            "Can't complain, work's been mental though.",
            "Same old, same old — counting down to the weekend.",
            "Been better honestly, but this helps.",
            "Busy few weeks, good to get out and clear my head.",
            "All good on my end, thanks for asking.",
            "Bit knackered if I'm honest, long week.",
            "Nothing much new, you know how it is.",
            "Actually really good, few things going right for once.",
            "Ticking along. This is the highlight of my week, though.",
            "Could be worse, could be better.",
            "Trying to save some money, so this is my one treat.",
            "Family's good, kids are a handful as always.",
            "Job's stressful but this makes it all worth it.",
            "Can't grumble, mate.",
            "Getting by. You know how it is out there.",
            "Honestly this is the one thing keeping me sane at the minute.",
            "Bit up and down, but I'm alright.",
            "All the usual nonsense, nothing worth mentioning.",
            "Good actually, cheers for asking.",
            "Same grind, different week.",
        ],
        .theClub: [
            "We're heading in the right direction, I reckon.",
            "Board need to back the manager in January, simple as.",
            "Still think we're a couple of players short.",
            "Love what the new manager's doing with this squad.",
            "I worry about where the money's going, if I'm honest.",
            "This is the best I've felt about the club in years.",
            "We need to sort the defence out before anything else.",
            "Proud of what we're building here.",
            "Ownership needs to show some ambition.",
            "Youth setup's looking strong, future's bright.",
            "Feels like we're stuck in a rut at the minute.",
            "Can't fault the effort, just need the results to follow.",
            "This club deserves better, honestly.",
            "I trust the process, for what it's worth.",
            "We've got a good core, just needs polishing.",
            "Ticket prices are getting out of hand though.",
            "Love the identity we've got as a club.",
            "Feels like we're a signing or two away from something special.",
            "The academy's the real gem here, watch this space.",
            "Whatever happens, I'll always be here.",
        ],
        .banter: [
            "Oi, you still owe me a pint from last season!",
            "Reckon you'd last five minutes on that away trip? Doubt it.",
            "Your last prediction was miles off, just saying.",
            "You call that a chant earlier? Embarrassing.",
            "Bet you can't even name the full squad.",
            "Heard you nearly missed kickoff again.",
            "You're still going on about that goal from years back, aren't you.",
            "State of your away record, honestly.",
            "You'd sell your season ticket for a good burger, wouldn't you.",
            "Don't think I've forgiven you for that prediction last month.",
            "You're worse than the ref today, and that's saying something.",
            "Reckon you'd cry if we got relegated, no shame in it.",
            "You still bring that ratty old scarf everywhere, don't you.",
            "Bet you didn't even watch the whole match, did you.",
            "You've jinxed us twice this season already.",
            "Your away-day stories get taller every time you tell them.",
            "You'd argue the sky isn't blue if it meant winding someone up.",
            "Still can't believe you slept through that away goal.",
            "You owe the whole crew a round after that bet.",
            "Go on then, tell everyone about the time you got lost on the away day.",
        ],
        .transferRumors: [
            "Heard we're closing in on a striker, but who knows with these rumors.",
            "If we actually land that one I'll run down the high street naked.",
            "Transfer window's exhausting, isn't it — refresh, refresh, refresh.",
            "I'll believe it when I see the unveiling photo.",
            "We need a new centre-back more than anything, forget strikers.",
            "That rumor's been going round for weeks now, nothing's come of it.",
            "My mate reckons he's seen the medical pics already.",
            "Board better back the manager in this window.",
            "Half these stories are just made up for clicks, honestly.",
            "If we sign him I might actually cry.",
            "We always get linked with someone and never land them.",
            "That fee seems way too high for what he offers.",
            "I'd take a steady defender over a flashy forward any day.",
            "Deadline day's going to be chaos as usual.",
            "Loan deal makes more sense than buying outright, if you ask me.",
            "I trust the scouting network on this one.",
            "Would rather we kept hold of what we've got, personally.",
            "That one's probably just an agent stirring up interest.",
            "Fingers crossed it's not another window of nothing happening.",
            "I'll wait for an official announcement before I get excited.",
        ],
        .rivalClub: [
            "Can't stand them, never could, never will.",
            "Their lot were absolutely everywhere last time we played them.",
            "Beating them means more than winning the league, honestly.",
            "They've gone quiet since that result against us.",
            "Their new manager's not going to save them.",
            "I still think about that derby winner years later.",
            "Their fans give it the big one until it matters.",
            "We own that fixture at the minute, long may it continue.",
            "Heard their group's shrinking, good riddance.",
            "That rivalry's the whole reason I got into this in the first place.",
            "Their away end was rough last time, stay switched on for the next one.",
            "I'd take a bad season over losing to them twice.",
            "Their history's nothing compared to ours, whatever they say.",
            "Can't wait for the fixture list, that date's circled already.",
            "They always seem to peak right before we play them.",
            "Say what you want, that's always the best atmosphere of the season.",
            "Their ultras have gone quiet since the takeover drama.",
            "I'd skip my own birthday for that fixture.",
            "We need to be at our loudest for that one, no excuses.",
            "That result against them is still getting mentioned down the pub.",
        ],
        .oldDays: [
            "Different world back then, wasn't it.",
            "Remember when tickets actually cost something reasonable.",
            "The old end had a different energy, say what you want about it now.",
            "I miss the terraces, if I'm honest.",
            "Some of the characters from back then don't come around any more.",
            "We used to walk to every home game as kids, rain or shine.",
            "The away trips were proper adventures back then.",
            "Nothing beats the stories from the old ground.",
            "Half the songs we sing now started back in those days.",
            "I still think about that cup run from years back.",
            "The club's changed so much since then, for better and worse.",
            "Used to know everyone in the stand by name.",
            "Wish the kids coming through now could've seen it.",
            "Say what you want, the football was worse but the atmosphere was better.",
            "That old scarf's seen more away days than most people have.",
            "First match I ever went to was with my old man, miss those days.",
            "We used to queue for hours just to get a ticket.",
            "The old chants hit different when you remember where they came from.",
            "Everything's changed except how much this still means to us.",
            "Funny how the old stories never get old themselves.",
        ],
    ]

    /// A random reply for `topic`, avoiding an immediate repeat of
    /// `previous` when there's more than one line to choose from — so two
    /// taps on the same topic in a row don't usually say the exact same
    /// thing.
    public static func randomResponse<G: RandomNumberGenerator>(
        for topic: ChatTopic, excluding previous: String? = nil, using generator: inout G
    ) -> String {
        let pool = responses[topic] ?? []
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
