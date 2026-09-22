import Foundation

/// Single source of truth for balance. Change numbers here to retune the
/// game without touching any engine logic.
///
/// Design intent: ranking up must NOT be simple. Four separate levers
/// enforce that together:
///   1. XP thresholds rise steeply per rank (roughly 3x each step).
///   2. Higher ranks additionally require a minimum number of matches
///      actually attended, a spread across several *different* activity
///      types (so repeating one cheap action can't carry you), a minimum
///      loyalty streak for the very top rank, and — for Lead Ultra and
///      Capo — specific achievements to already be unlocked.
///   3. Each activity's XP/stat reward diminishes the more times it's
///      repeated on the same day, so grinding a single action in one
///      sitting has a hard ceiling.
///   4. The XP thresholds themselves scale by the fan's club — a fan of
///      one of the biggest, most historically dominant clubs needs more
///      XP for the same rank than a fan of a smaller one. See
///      `xpMultiplier(forPrestigeTier:)`.
public enum ProgressionConstants {

    // MARK: - Activity rewards

    public static let activityRewards: [ActivityType: ActivityReward] = [
        .attendMatch: ActivityReward(xp: 38, loyalty: 4, knowledge: 1, influence: 1, notoriety: 0),
        .sitInUltrasStand: ActivityReward(xp: 22, loyalty: 5, knowledge: 0, influence: 2, notoriety: 1),
        .doPyroChallenge: ActivityReward(xp: 30, loyalty: 1, knowledge: 0, influence: 2, notoriety: 6),
        .participateInChant: ActivityReward(xp: 15, loyalty: 2, knowledge: 4, influence: 1, notoriety: 0),
        .contributeToTifo: ActivityReward(xp: 25, loyalty: 2, knowledge: 3, influence: 3, notoriety: 1),
        .completeTask: ActivityReward(xp: 18, loyalty: 2, knowledge: 2, influence: 2, notoriety: 0),
        .dailyLoyaltyCheckIn: ActivityReward(xp: 5, loyalty: 1, knowledge: 0, influence: 0, notoriety: 0),
        .socializeWithCrew: ActivityReward(xp: 15, loyalty: 1, knowledge: 0, influence: 3, notoriety: 0),
        .launchClothingRange: ActivityReward(xp: 30, loyalty: 0, knowledge: 0, influence: 5, notoriety: 10),
        .reactMildly: ActivityReward(xp: 4, loyalty: 1, knowledge: 0, influence: 0, notoriety: 0),
        .reactModerately: ActivityReward(xp: 7, loyalty: 1, knowledge: 0, influence: 1, notoriety: 2),
        .reactStrongly: ActivityReward(xp: 12, loyalty: 0, knowledge: 0, influence: 2, notoriety: 6),
        .reactExtremely: ActivityReward(xp: 18, loyalty: 0, knowledge: 0, influence: 3, notoriety: 14),
    ]

    /// Bond-score bump every crew member gets when the player launches a
    /// clothing range — they bought in and it shows.
    public static let clothingRangeCrewBondBonus = 5

    // MARK: - Diminishing returns

    /// How many times per day an activity pays out its full reward before
    /// decaying.
    public static let diminishingReturnsFreeOccurrencesPerDay = 1
    /// Multiplicative decay applied per occurrence beyond the free count.
    public static let diminishingReturnsDecayFactor = 0.5
    /// Reward never decays below this fraction of the base reward, so an
    /// activity always grants *something* but stops being worth repeating.
    public static let diminishingReturnsFloor = 0.12

    /// Returns the multiplier (0...1] to apply to an activity's base reward
    /// given it's the `occurrenceIndexToday`-th time (1-based) that activity
    /// has been performed today.
    public static func diminishingReturnsMultiplier(occurrenceIndexToday: Int) -> Double {
        guard occurrenceIndexToday > diminishingReturnsFreeOccurrencesPerDay else { return 1.0 }
        let decaySteps = occurrenceIndexToday - diminishingReturnsFreeOccurrencesPerDay
        let decayed = pow(diminishingReturnsDecayFactor, Double(decaySteps))
        return max(diminishingReturnsFloor, decayed)
    }

    // MARK: - Activity diversity

    /// Activity types that count toward "activity diversity" gating.
    /// `dailyLoyaltyCheckIn` is excluded — it's a passive, automatic action,
    /// not a deliberate one, so it shouldn't help satisfy a diversity gate.
    public static let coreDiversityActivityTypes: Set<ActivityType> = [
        .attendMatch, .sitInUltrasStand, .doPyroChallenge,
        .participateInChant, .contributeToTifo, .completeTask,
    ]

    /// Given lifetime counts per activity type, how many *distinct* core
    /// activity types has the player performed at least once.
    public static func activityDiversity(activityCounts: [ActivityType: Int]) -> Int {
        coreDiversityActivityTypes.reduce(into: 0) { total, type in
            if (activityCounts[type] ?? 0) > 0 { total += 1 }
        }
    }

    // MARK: - Club prestige → XP difficulty

    /// How much harder (or easier) it is to earn rank-qualifying XP as a
    /// fan of a club at each `Club.prestigeTier` (1 = smallest, 5 = global
    /// giant). Applied only to XP thresholds — activity-diversity, matches
    /// attended, streak, and achievement gates stay the same for everyone,
    /// so following a huge club doesn't change *what* you have to do, only
    /// how much XP it's worth to that rank.
    public static let prestigeXPMultiplier: [Int: Double] = [
        1: 0.7,
        2: 0.85,
        3: 1.0,
        4: 1.3,
        5: 1.6,
    ]

    /// Falls back to 1.0 (no adjustment) for an out-of-range tier.
    public static func xpMultiplier(forPrestigeTier tier: Int) -> Double {
        prestigeXPMultiplier[tier] ?? 1.0
    }

    // MARK: - Home season ticket (Ultras Section)

    /// Loyalty points needed to earn a standing season ticket in the
    /// favorite club's ultras section, by `Club.prestigeTier` — bigger,
    /// more oversubscribed clubs take longer to build enough loyalty for.
    /// Loyalty accrues slowly (a few points per activity, with the same
    /// daily diminishing returns as everything else), so this is
    /// deliberately a multi-session commitment, not a single evening.
    public static let seasonTicketLoyaltyThreshold: [Int: Int] = [
        1: 40,
        2: 70,
        3: 120,
        4: 180,
        5: 280,
    ]

    /// Falls back to the tier-3 threshold for an out-of-range tier.
    public static func loyaltyThresholdForSeasonTicket(prestigeTier: Int) -> Int {
        seasonTicketLoyaltyThreshold[prestigeTier] ?? 120
    }

    public static func hasEarnedSeasonTicket(loyalty: Int, prestigeTier: Int) -> Bool {
        loyalty >= loyaltyThresholdForSeasonTicket(prestigeTier: prestigeTier)
    }

    // MARK: - Away tickets

    /// Away loyalty points needed before an away ticket for the favorite
    /// club is *guaranteed*, by `Club.prestigeTier` — bigger clubs sell out
    /// more away allocations, so it takes longer to become a certainty.
    public static let awayTicketGuaranteedThresholdByTier: [Int: Int] = [
        1: 20,
        2: 35,
        3: 60,
        4: 90,
        5: 140,
    ]

    /// Falls back to the tier-3 threshold for an out-of-range tier.
    public static func awayTicketGuaranteedThreshold(forPrestigeTier tier: Int) -> Int {
        awayTicketGuaranteedThresholdByTier[tier] ?? 60
    }

    /// Chance of getting an away ticket with zero away loyalty points —
    /// tickets are scarce, but never impossible, even for a first-timer.
    public static let awayTicketBaseChance = 0.3

    /// Away loyalty gained from a successful trip vs. an unsuccessful
    /// attempt — even missing out on a ticket counts for something, so a
    /// run of bad luck isn't a dead end.
    public static let awayTicketSuccessLoyaltyGain = 6
    public static let awayTicketConsolationLoyaltyGain = 1

    /// Extra away loyalty for taking the bus (see `TravelMode`) — applies
    /// whether or not the ticket request succeeds, since the bonding
    /// happens on the ride, not just at the turnstile.
    public static let busTravelAwayLoyaltyBonus = 2

    /// The chance (0...1) of getting an away ticket this time, given the
    /// character's current away loyalty points and their favorite club's
    /// prestige tier. Rises linearly from `awayTicketBaseChance` to a
    /// guaranteed 1.0 at `awayTicketGuaranteedThreshold(forPrestigeTier:)`.
    public static func awayTicketChance(awayLoyaltyPoints: Int, prestigeTier: Int) -> Double {
        let threshold = awayTicketGuaranteedThreshold(forPrestigeTier: prestigeTier)
        guard threshold > 0 else { return 1.0 }
        let progress = Double(awayLoyaltyPoints) / Double(threshold)
        return min(1.0, awayTicketBaseChance + (1.0 - awayTicketBaseChance) * progress)
    }

    // MARK: - Achievement IDs used as rank gates

    /// These must exist with matching criteria in the bundled
    /// `achievements_catalog.json` — see `App/Resources/Content`.
    public enum GatingAchievementID {
        public static let pyroVeteran = "pyro-veteran"
        public static let tifoArtist = "tifo-artist"
        public static let chantMaster = "chant-master"
        public static let dieHard = "die-hard"
    }

    // MARK: - Rank requirements

    public static let rankRequirements: [RankRequirement] = [
        RankRequirement(
            rank: .regular,
            minimumXP: 0
        ),
        RankRequirement(
            rank: .youngUltra,
            minimumXP: 420,
            minimumMatchesAttended: 5
        ),
        RankRequirement(
            rank: .ultraGroup,
            minimumXP: 1400,
            minimumMatchesAttended: 15,
            minimumActivityDiversity: 4
        ),
        RankRequirement(
            rank: .leadUltra,
            minimumXP: 3400,
            minimumMatchesAttended: 30,
            minimumActivityDiversity: 6,
            requiredAchievementIDs: [GatingAchievementID.pyroVeteran]
        ),
        RankRequirement(
            rank: .capo,
            minimumXP: 6800,
            minimumMatchesAttended: 50,
            minimumActivityDiversity: 6,
            minimumStreakDays: 30,
            requiredAchievementIDs: [
                GatingAchievementID.pyroVeteran,
                GatingAchievementID.tifoArtist,
                GatingAchievementID.chantMaster,
                GatingAchievementID.dieHard,
            ]
        ),
    ]
}
