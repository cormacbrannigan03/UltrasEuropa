import Foundation

/// Single source of truth for balance. Change numbers here to retune the
/// game without touching any engine logic.
///
/// Design intent: ranking up must NOT be simple. Three separate levers
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
public enum ProgressionConstants {

    // MARK: - Activity rewards

    public static let activityRewards: [ActivityType: ActivityReward] = [
        .attendMatch: ActivityReward(xp: 50, loyalty: 4, knowledge: 1, influence: 1, notoriety: 0),
        .sitInUltrasStand: ActivityReward(xp: 30, loyalty: 5, knowledge: 0, influence: 2, notoriety: 1),
        .doPyroChallenge: ActivityReward(xp: 40, loyalty: 1, knowledge: 0, influence: 2, notoriety: 6),
        .participateInChant: ActivityReward(xp: 20, loyalty: 2, knowledge: 4, influence: 1, notoriety: 0),
        .contributeToTifo: ActivityReward(xp: 35, loyalty: 2, knowledge: 3, influence: 3, notoriety: 1),
        .completeTask: ActivityReward(xp: 25, loyalty: 2, knowledge: 2, influence: 2, notoriety: 0),
        .dailyLoyaltyCheckIn: ActivityReward(xp: 5, loyalty: 1, knowledge: 0, influence: 0, notoriety: 0),
    ]

    // MARK: - Diminishing returns

    /// How many times per day an activity pays out its full reward before
    /// decaying.
    public static let diminishingReturnsFreeOccurrencesPerDay = 2
    /// Multiplicative decay applied per occurrence beyond the free count.
    public static let diminishingReturnsDecayFactor = 0.55
    /// Reward never decays below this fraction of the base reward, so an
    /// activity always grants *something* but stops being worth repeating.
    public static let diminishingReturnsFloor = 0.15

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
            minimumXP: 300,
            minimumMatchesAttended: 5
        ),
        RankRequirement(
            rank: .ultraGroup,
            minimumXP: 900,
            minimumMatchesAttended: 15,
            minimumActivityDiversity: 4
        ),
        RankRequirement(
            rank: .leadUltra,
            minimumXP: 2200,
            minimumMatchesAttended: 30,
            minimumActivityDiversity: 6,
            requiredAchievementIDs: [GatingAchievementID.pyroVeteran]
        ),
        RankRequirement(
            rank: .capo,
            minimumXP: 4500,
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
