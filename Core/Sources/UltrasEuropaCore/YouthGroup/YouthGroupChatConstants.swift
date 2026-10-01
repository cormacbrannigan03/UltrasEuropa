import Foundation

/// The group's side of a youth-group chat conversation — 10 generic replies
/// per `YouthGroupChatTopic`, picked at random whenever the player posts
/// that topic. Deliberately generic, same reasoning as
/// `CrewChatConstants`'s messages: these stand in for whichever of the
/// player's recruited members happens to answer, not a specific person.
public enum YouthGroupChatConstants {
    public static let responses: [YouthGroupChatTopic: [String]] = [
        .awayDayPlan: [
            "Count me in, wouldn't miss it.",
            "Already sorted the day off work for that one.",
            "Big away day, everyone needs to be there.",
            "In if the coach is sorted in time.",
            "Wouldn't miss this one for the world.",
            "Depends on work but I'll try my best.",
            "Let's make some noise down there.",
            "In. Who else is coming?",
            "That's a big ask that far, but I'm up for it.",
            "Already told the lads, we're all in.",
        ],
        .meetupTime: [
            "Usual spot, two hours before kickoff?",
            "Works for me, I'll be there early anyway.",
            "Can we push it back half an hour? Work runs late.",
            "Sound, I'll let the others know.",
            "Same time as always, nothing's changed has it?",
            "I'll grab a table at the pub for everyone.",
            "That works, see you all there.",
            "Might be a bit late, don't wait on me.",
            "Perfect, gives us time for a few pints first.",
            "Noted. I'll spread the word.",
        ],
        .tifoPlan: [
            "Love that, let's get the materials sorted.",
            "Big idea — gonna need a few extra hands though.",
            "I know someone who can help paint it.",
            "That'll look brilliant on matchday.",
            "Bit short notice but we can make it work.",
            "I'm in, just tell me what you need doing.",
            "We did something similar a while back, let's go bigger.",
            "Budget might be tight, but let's see what we can do.",
            "That's exactly the kind of thing we should be doing more of.",
            "I'll bring the paint if someone sorts the fabric.",
        ],
        .transportPlan: [
            "I've got room for two more in the car.",
            "Could use a lift if anyone's got space.",
            "I'll drive, just let me know numbers.",
            "Train's probably easier for me this time.",
            "Sorted, cheers for organizing it.",
            "I can take the early one if that helps.",
            "Count me in for the car share.",
            "I'll sort my own way there, but appreciate the offer.",
            "Let's split the fuel cost between us.",
            "Works for me, what time are we setting off?",
        ],
        .pyroPlan: [
            "Say no more, I'm in.",
            "Keep me posted on the details.",
            "Bold move, let's make it count.",
            "I'll keep watch if you need it.",
            "That's the spirit, can't wait.",
            "Careful with that, but I'm backing it.",
            "Let's not get carried away, but yeah, I'm in.",
            "Say nothing, just tell me where to stand.",
            "That'll get the whole end bouncing.",
            "Understood. Not a word to anyone else.",
        ],
    ]

    /// A random reply for `topic`, avoiding an immediate repeat of
    /// `previous` when there's more than one line to choose from.
    public static func randomResponse<G: RandomNumberGenerator>(
        for topic: YouthGroupChatTopic, excluding previous: String? = nil, using generator: inout G
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
