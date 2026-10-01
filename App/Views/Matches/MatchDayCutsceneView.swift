import SwiftUI
import UltrasEuropaCore

/// The full-screen "you're at the match" sequence, presented once
/// attendance is locked in (seat picked, away ticket granted, or the
/// neutral toggle confirmed) — arriving (by bus/train first, for an away
/// day), a security search if carrying pyro, watching the match live with
/// a reaction to each goal, joining in the chant, raising a tifo if one's
/// prepared for this fixture, and a closing summary. This is where
/// `.participateInChant`, `.contributeToTifo`, and `.reactMildly`...
/// `.reactExtremely` actually get earned now — not standalone menu buttons
/// reachable from anywhere, anytime.
struct MatchDayCutsceneView: View {
    let match: Match
    let homeClub: Club?
    let awayClub: Club?
    /// Non-nil only for an away day — decides the travel beat and its flavor.
    let travelMode: TravelMode?
    let satInUltrasStand: Bool
    let didPyro: Bool
    /// When the player plans to light their pyro, chosen up front on the
    /// match screen — only meaningful when `didPyro` is true. See
    /// `pendingPyroPrompt`.
    let pyroMoment: PyroMoment

    @Environment(CharacterStore.self) private var characterStore
    @Environment(ContentStore.self) private var contentStore
    @Environment(\.dismiss) private var dismiss

    private enum Beat: Equatable {
        case travel
        case arrival
        case confrontation
        case security
        case liveMatch
        case chant
        case tifo
        case summary
    }

    /// How fast the live-match clock's real-time ticking runs — a pacing
    /// preference the player can change mid-match, not a change to how the
    /// match itself plays out. Scales the tick interval directly rather
    /// than how many minutes advance per tick, so the clock still counts
    /// up one minute at a time either way.
    private enum MatchSpeed: Double, CaseIterable {
        case normal = 1.0
        case fast = 1.5
        case veryFast = 2.0

        var displayName: String {
            switch self {
            case .normal: return "×1"
            case .fast: return "×1.5"
            case .veryFast: return "×2"
            }
        }
    }

    @State private var beatIndex = 0
    @State private var didJoinChant = false
    @State private var didContributeTifo = false

    @State private var selectedHidingSpot: PyroHidingSpot = .insideJacket
    @State private var securitySearchResolved = false
    @State private var pyroConfiscated = false

    @State private var currentMinute = 0
    /// How fast the live-match clock ticks in real time — see
    /// `MatchSpeed` and `matchSpeedPicker`. Purely a pacing preference;
    /// doesn't change anything about what happens during the match.
    @State private var matchSpeed: MatchSpeed = .normal
    @State private var acknowledgedGoalIDs: Set<String> = []
    @State private var pendingReactionGoal: GoalEvent?
    /// Drives the pop-in animation on the "GOAL FOR ...!!" banner each
    /// time `reactionPromptCard(for:)` appears for a new goal — reset to
    /// `false` first so the spring replays even if the same view instance
    /// is reused for back-to-back goals.
    @State private var goalBannerDidAppear = false
    @State private var acknowledgedCardIDs: Set<String> = []
    @State private var pendingReactionCard: CardEvent?
    @State private var reactionSeverities: [ReactionSeverity] = []
    @State private var heat = 0
    @State private var securityOutcome: SecurityOutcome = .noAction

    /// Non-nil while the "light it now?" prompt for the player's chosen
    /// `pyroMoment` is being shown. `didOfferPyroPrompt` guards against
    /// offering more than once per match, and `didLightPyro` records
    /// whether the one opportunity was taken.
    @State private var pendingPyroPrompt = false
    @State private var didOfferPyroPrompt = false
    @State private var didLightPyro = false

    /// The supporting style the player is currently keeping up, or `nil`
    /// before it's first chosen (right at kickoff) or after choosing to
    /// ease off at a checkpoint — see `MatchStance`.
    @State private var currentStance: MatchStance?
    @State private var acknowledgedCheckpoints: Set<Int> = []
    /// Non-nil while the "keep it up or ease off?" check-in for this
    /// checkpoint is being shown.
    @State private var pendingCheckpointMinute: Int?
    @State private var diaryEntries: [String] = []
    @State private var lastDiaryLineByStance: [MatchStance: String] = [:]
    /// Guards against `liveMatchCard`'s `.task` re-firing every time the
    /// reaction prompt swaps it out and back in — the goal reaction cycle
    /// tears down and remounts that view repeatedly, but base attendance
    /// must only ever be recorded once per match day.
    @State private var didRecordBaseActivities = false

    @State private var rankBefore: Rank = .regular
    @State private var totalXP = 0
    @State private var achievements: [Achievement] = []
    @State private var items: [InventoryItem] = []
    @State private var membershipAnnouncement: String?
    @State private var seasonTicketAnnouncement: String?

    /// XP earned (or lost) this match, broken down by where it came from —
    /// shown as a chart on the full-time summary. See `absorb(_:source:)`.
    @State private var xpBySource: [XPSource: Int] = [:]
    @State private var loyaltyDelta = 0
    @State private var knowledgeDelta = 0
    @State private var influenceDelta = 0
    @State private var notorietyDelta = 0
    /// Guards the one-time low-involvement check against `summaryCard`
    /// being re-evaluated on every render.
    @State private var didApplyMatchWrapUp = false
    /// Guards the one-time interstitial-ad check against `summaryCard`
    /// being re-evaluated on every render — separate from
    /// `didApplyMatchWrapUp` since it has its own (non-overlapping)
    /// eligibility rule, see `summaryCard`'s second `.task`.
    @State private var didCheckInterstitial = false
    @State private var interstitialAdCoordinator = InterstitialAdCoordinator()
    /// The rewarded ad backing "Watch Ad to Double XP" — offered after
    /// every clean Full Time (not capped like the interstitial, since
    /// it's the player's choice to take it), but still suppressed by
    /// `CharacterStore.hasRemovedAds` like every other ad surface — "no
    /// ads" means zero ads, with no opt-in exception.
    @State private var rewardedAdCoordinator = RewardedAdCoordinator()
    /// Guards against doubling the same match's XP twice, and hides the
    /// offer once it's been taken.
    @State private var didDoubleXP = false

    /// Where a chunk of match-day XP came from, for the full-time XP chart.
    private enum XPSource: String, CaseIterable, Hashable {
        case attendance = "Attendance"
        case reactions = "Reactions"
        case singing = "Supporting Style"
        case pyro = "Pyro"
        case chantAndTifo = "Chant & Tifo"
        case confrontation = "Confrontation"
        case involvement = "Involvement"
        case adBonus = "Ad Bonus"
    }

    private var chant: Chant? { contentStore.repository.chantOfTheDay(matchId: match.id) }
    private var tifo: TifoPhoto? { contentStore.repository.preparedTifo(matchId: match.id) }

    /// Whether the player still actually has the pyro to use — `false` if
    /// it was never brought, or if security caught it at the door.
    private var effectiveHasPyro: Bool { didPyro && !pyroConfiscated }

    /// The match's live state as of right now — re-derived fresh from the
    /// season clock rather than the `match` snapshot passed in, so it
    /// reflects a "Fast Forward to Kickoff" tap made during this beat.
    private var currentMatchState: Match {
        characterStore.matchesForClub(match.homeClubId).first { $0.id == match.id } ?? match
    }

    private var liveGoalEvents: [GoalEvent] {
        let state = currentMatchState
        guard let home = state.homeScore, let away = state.awayScore else { return [] }
        return MatchDayContentPlanner.goalEvents(matchId: match.id, homeGoals: home, awayGoals: away)
    }

    private var visibleGoalEvents: [GoalEvent] {
        liveGoalEvents.filter { $0.minute <= currentMinute }
    }

    private var liveCardEvents: [CardEvent] {
        MatchDayContentPlanner.cardEvents(matchId: match.id)
    }

    private var visibleCardEvents: [CardEvent] {
        liveCardEvents.filter { $0.minute <= currentMinute }
    }

    /// Goals and cards merged into one chronological feed for the live-watch
    /// card — see `feedEntryRow`.
    private var visibleFeedEntries: [FeedEntry] {
        (visibleGoalEvents.map(FeedEntry.goal) + visibleCardEvents.map(FeedEntry.card))
            .sorted { $0.minute < $1.minute }
    }

    /// This fixture's fabricated match stats — see `MatchStatsEngine`. `nil`
    /// until the match has actually been played.
    private var matchStats: MatchStats? {
        let state = currentMatchState
        guard let home = state.homeScore, let away = state.awayScore else { return nil }
        return MatchStatsEngine.generate(matchId: match.id, homeGoals: home, awayGoals: away)
    }

    /// Deterministic, random-feeling stops (always including full time)
    /// where the live-watch beat pauses for a stance check-in regardless of
    /// whether a goal happens to land there too — see `MatchStance` and
    /// `MatchDayContentPlanner.stanceCheckpointMinutes`.
    private var checkpointMinutes: [Int] {
        MatchDayContentPlanner.stanceCheckpointMinutes(matchId: match.id)
    }

    /// This fixture's police/rivalry profile — see `MatchProfileEngine`.
    /// Category 3 fixtures are too low-key for a confrontation opportunity
    /// to come up at all.
    private var matchCategory: MatchCategory {
        characterStore.matchCategory(for: match)
    }

    /// The locked-in outcome of a confrontation attempt for this match, if
    /// one's been made — read straight from the store rather than
    /// duplicated into local `@State`, same pattern `MatchDetailView` uses
    /// for away-ticket/home-seat results.
    private var ultraViolenceIncident: (role: UltraViolenceRole, policeIntervention: Bool)? {
        characterStore.ultraViolenceIncident(forMatchId: match.id)
    }

    private var wasPoliceIntervened: Bool {
        ultraViolenceIncident?.policeIntervention == true
    }

    private var beats: [Beat] {
        var beats: [Beat] = []
        if travelMode != nil { beats.append(.travel) }
        beats.append(.arrival)
        if matchCategory != .three { beats.append(.confrontation) }
        if didPyro { beats.append(.security) }
        beats.append(.liveMatch)
        beats.append(.chant)
        if tifo != nil { beats.append(.tifo) }
        beats.append(.summary)
        return beats
    }

    private var currentBeat: Beat {
        let all = beats
        return all.indices.contains(beatIndex) ? all[beatIndex] : .summary
    }

    private var wasEjected: Bool {
        switch securityOutcome {
        case .ejected, .ejectedWithBan: return true
        case .noAction, .warned: return false
        }
    }

    private var summary: AttendanceSummary {
        AttendanceSummary(
            xpAwarded: totalXP,
            didRankUp: characterStore.rank > rankBefore,
            newRank: characterStore.rank,
            newlyUnlockedAchievements: achievements,
            newlyUnlockedItems: items,
            membershipAnnouncement: membershipAnnouncement,
            seasonTicketAnnouncement: seasonTicketAnnouncement,
            ticketDenied: false
        )
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            beatContent
            Spacer()
            actionButton
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.secondaryText)
            }
            .padding()
        }
    }

    // MARK: - Beats

    @ViewBuilder
    private var beatContent: some View {
        switch currentBeat {
        case .travel:
            if let travelMode {
                sceneCard(
                    symbolName: travelMode == .bus ? "bus.fill" : "tram.fill",
                    title: travelMode == .bus ? "On the Bus" : "On the Train",
                    body: "Riding the \(travelMode.displayName.lowercased()) with the crew, buzzing for kickoff."
                )
            }
        case .arrival:
            sceneCard(
                symbolName: "flag.fill",
                title: "You've Arrived",
                body: "You arrive at \(match.venue), \((homeClub?.name).map { "home of \($0)" } ?? "")."
            )
        case .confrontation:
            confrontationCard
        case .security:
            securityCard
        case .liveMatch:
            if let pendingReactionGoal {
                reactionPromptCard(for: pendingReactionGoal)
            } else if let pendingReactionCard {
                reactionPromptCard(for: pendingReactionCard)
            } else if pendingPyroPrompt {
                pyroPromptCard
            } else if let pendingCheckpointMinute {
                stanceCheckInCard(at: pendingCheckpointMinute)
            } else if currentMatchState.isPlayed && currentStance == nil && currentMinute == 0 {
                stanceSelectionCard
            } else {
                liveMatchCard
            }
        case .chant:
            chantCard
        case .tifo:
            tifoCard
        case .summary:
            summaryCard
        }
    }

    private func sceneCard(symbolName: String, title: String, body: String) -> some View {
        VStack(spacing: 16) {
            PlaceholderArt(
                primaryColorHex: homeClub?.primaryColorHex ?? Theme.crewPrimaryHex,
                secondaryColorHex: homeClub?.secondaryColorHex ?? Theme.crewSecondaryHex,
                symbolName: symbolName
            )
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Text(title).font(.title2.bold())
            Text(body).multilineTextAlignment(.center).foregroundStyle(Theme.secondaryText)
        }
    }

    // MARK: - Confrontation (police presence / ultra violence)

    private var confrontationCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            Text("\(matchCategory.displayName) Fixture").font(.title2.bold())
            Text(matchCategory.policePresenceDescription)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.secondaryText)

            if let ultraViolenceIncident {
                if ultraViolenceIncident.policeIntervention {
                    Label("Police Stepped In", systemImage: "exclamationmark.shield.fill")
                        .font(.headline)
                        .foregroundStyle(.red)
                } else {
                    Label("You Got Away With It", systemImage: "checkmark.shield.fill")
                        .font(.headline)
                        .foregroundStyle(Theme.accent)
                    Text(ultraViolenceIncident.role == .instigator ? "You called it — and got clean away." : "You piled in and slipped away before anyone noticed.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.secondaryText)
                }
            } else {
                Text("A rival firm has been spotted nearby. Some of the crew are squaring up to them.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }

    private func resolveUltraViolence(role: UltraViolenceRole) {
        guard let result = characterStore.attemptUltraViolence(role: role, for: match) else { return }
        absorb(result.xpOutcome, source: .confrontation)
        if case .policeIntervention = result.outcome {
            jumpToSummary()
        }
    }

    // MARK: - Security search

    private var securityCard: some View {
        VStack(spacing: 16) {
            if !securitySearchResolved {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.secondaryText)
                Text("Security Search").font(.title2.bold())
                Text("You're carrying pyro. Where do you hide it before the pat-down?")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.secondaryText)

                VStack(spacing: 8) {
                    ForEach(PyroHidingSpot.allCases, id: \.self) { spot in
                        Button {
                            selectedHidingSpot = spot
                        } label: {
                            HStack {
                                Image(systemName: selectedHidingSpot == spot ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(Theme.accent)
                                Text(spot.displayName).foregroundStyle(Theme.primaryText)
                                Spacer()
                            }
                            .padding(10)
                            .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            } else if pyroConfiscated {
                Image(systemName: "xmark.shield.fill").font(.system(size: 48)).foregroundStyle(.red)
                Text("Caught").font(.title2.bold())
                Text("Security found the pyro and confiscated it before you got in.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.secondaryText)
            } else {
                Image(systemName: "checkmark.shield.fill").font(.system(size: 48)).foregroundStyle(Theme.accent)
                Text("You're In").font(.title2.bold())
                Text("The pyro made it past the search.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }

    // MARK: - Live match

    /// Watching the match unfold — if the season clock hasn't reached
    /// kickoff yet, prompts to fast forward instead of showing a
    /// scoreboard; once it has, lets the player continue toward each of
    /// `liveGoalEvents` in turn, ending at the same fixed final score
    /// `SeasonScheduleGenerator` already generated for this match.
    private var liveMatchCard: some View {
        ScrollView {
            VStack(spacing: 16) {
                if !currentMatchState.isPlayed {
                    Image(systemName: "hourglass")
                        .font(.system(size: 48))
                        .foregroundStyle(Theme.secondaryText)
                    Text("Kickoff Hasn't Happened Yet").font(.title2.bold())
                    Text("It's still \(characterStore.simulatedDate.formatted(date: .abbreviated, time: .omitted)) — fast forward to \(match.date.formatted(date: .abbreviated, time: .omitted)) to watch this one live.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.secondaryText)
                } else {
                    Text(match.competition)
                        .font(.caption.bold())
                        .textCase(.uppercase)
                        .foregroundStyle(Theme.secondaryText)

                    LiveMatchPitchView(
                        homeColorHex: homeClub?.primaryColorHex ?? Theme.crewPrimaryHex,
                        awayColorHex: awayClub?.primaryColorHex ?? Theme.crewSecondaryHex
                    )

                    Text("\(currentMinute)'")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.accent)

                    HStack(spacing: 20) {
                        scoreColumn(name: homeClub?.name ?? match.homeClubId, goals: visibleGoalEvents.filter(\.isHomeTeam).count)
                        Text("-").font(.title.bold()).foregroundStyle(Theme.secondaryText)
                        scoreColumn(name: awayClub?.name ?? match.awayClubId, goals: visibleGoalEvents.filter { !$0.isHomeTeam }.count)
                    }

                    if securityOutcome == .warned {
                        Label("Security is watching you closely", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    if didLightPyro {
                        Label("Pyro lit", systemImage: "flame.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(visibleFeedEntries) { entry in
                            feedEntryRow(entry)
                        }
                    }

                    if !diaryEntries.isEmpty {
                        Divider()
                        VStack(alignment: .leading, spacing: 4) {
                            Text(currentStance.map { "Your \($0.displayName) Diary" } ?? "Your Matchday Diary")
                                .font(.caption.bold())
                                .foregroundStyle(Theme.secondaryText)
                            ForEach(Array(diaryEntries.enumerated()), id: \.offset) { _, entry in
                                Text(entry).font(.caption).foregroundStyle(Theme.secondaryText)
                            }
                        }
                    }
                }
            }
        }
        .task(id: currentMatchState.isPlayed) {
            guard currentMatchState.isPlayed, !didRecordBaseActivities else { return }
            didRecordBaseActivities = true
            rankBefore = characterStore.rank
            recordBaseActivities()
            if pyroMoment == .kickoff {
                offerPyroPromptIfNeeded()
            }
        }
        .onReceive(Timer.publish(every: 0.4 / matchSpeed.rawValue, on: .main, in: .common).autoconnect()) { _ in
            advanceClockTick()
        }
    }

    /// Ticks the live-match clock forward by a minute, run continuously by
    /// `liveMatchCard`'s timer rather than jumping straight to the next
    /// goal/card/checkpoint — this view is swapped out for a prompt card
    /// whenever one comes up, which naturally pauses the ticking, and swapped
    /// back in (resuming it) once that prompt resolves.
    private func advanceClockTick() {
        guard currentMatchState.isPlayed, currentMinute < MatchDayContentPlanner.matchLengthMinutes else { return }
        currentMinute += 1
        if let goal = liveGoalEvents.first(where: { $0.minute == currentMinute && !acknowledgedGoalIDs.contains($0.id) }) {
            pendingReactionGoal = goal
        } else {
            advanceWithinLiveMatch()
        }
    }

    private func scoreColumn(name: String, goals: Int) -> some View {
        VStack(spacing: 4) {
            Text(name).font(.caption).multilineTextAlignment(.center).foregroundStyle(Theme.secondaryText)
            Text("\(goals)").font(.title.bold())
        }
        .frame(maxWidth: .infinity)
    }

    /// A goal or a card, merged into one chronologically-sorted feed for
    /// `liveMatchCard` — see `visibleFeedEntries`.
    private enum FeedEntry: Identifiable {
        case goal(GoalEvent)
        case card(CardEvent)

        var id: String {
            switch self {
            case .goal(let event): return event.id
            case .card(let event): return event.id
            }
        }

        var minute: Int {
            switch self {
            case .goal(let event): return event.minute
            case .card(let event): return event.minute
            }
        }
    }

    @ViewBuilder
    private func feedEntryRow(_ entry: FeedEntry) -> some View {
        switch entry {
        case .goal(let event):
            Text("⚽️ \(event.minute)' — \(event.scorerName) (\((event.isHomeTeam ? homeClub?.name : awayClub?.name) ?? "Goal!"))")
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
        case .card(let event):
            Text("\(event.isRed ? "🟥" : "🟨") \(event.minute)' — \(event.playerName) (\((event.isHomeTeam ? homeClub?.name : awayClub?.name) ?? "Card"))")
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
        }
    }

    // MARK: - Match stance

    private var stanceSelectionCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "megaphone.fill").font(.system(size: 48)).foregroundStyle(Theme.accent)
            Text("How Are You Supporting Today?").font(.title2.bold())
            Text("Pick how you'll spend the next 90 minutes. You can ease off later if it's not going your way.")
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.secondaryText)
        }
    }

    private func stanceCheckInCard(at minute: Int) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "gauge.medium").font(.system(size: 48)).foregroundStyle(Theme.accent)
            Text("\(minute)' — Keep It Up?").font(.title2.bold())

            HStack(spacing: 20) {
                scoreColumn(name: homeClub?.name ?? match.homeClubId, goals: visibleGoalEvents.filter(\.isHomeTeam).count)
                Text("-").font(.title.bold()).foregroundStyle(Theme.secondaryText)
                scoreColumn(name: awayClub?.name ?? match.awayClubId, goals: visibleGoalEvents.filter { !$0.isHomeTeam }.count)
            }

            if let currentStance {
                Text("You've been \(currentStance.displayName.lowercased()) so far.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }

    private func resolveCheckpoint(keepGoing: Bool) {
        guard let minute = pendingCheckpointMinute else { return }
        acknowledgedCheckpoints.insert(minute)
        pendingCheckpointMinute = nil

        if keepGoing, let stance = currentStance {
            var generator = SystemRandomNumberGenerator()
            let line = MatchStanceConstants.randomLine(for: stance, excluding: lastDiaryLineByStance[stance], using: &generator)
            lastDiaryLineByStance[stance] = line
            diaryEntries.append("\(minute)' — \(line)")

            applyHeat(stance.heatPerCheckpoint)

            if minute == MatchDayContentPlanner.matchLengthMinutes, !wasEjected {
                absorb(characterStore.recordActivity(stance.activityType), source: .singing)
            }
        } else {
            diaryEntries.append("\(minute)' — You ease off and just watch the rest unfold.")
            currentStance = nil
        }
    }

    private func reactionPromptCard(for goal: GoalEvent) -> some View {
        let isOwnGoalForFavorite = isGoalForFavoriteClub(goal)
        let scoringClubName = (goal.isHomeTeam ? homeClub?.name : awayClub?.name) ?? "Goal"
        let scoringColorHex = (goal.isHomeTeam ? homeClub?.primaryColorHex : awayClub?.primaryColorHex) ?? Theme.crewPrimaryHex
        return VStack(spacing: 16) {
            Image(systemName: "soccerball")
                .font(.system(size: 48))
                .foregroundStyle(Theme.accent)
            Text("GOAL FOR \(scoringClubName.uppercased())!!")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(hex: scoringColorHex))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(hex: scoringColorHex).opacity(0.18), in: RoundedRectangle(cornerRadius: 12))
                .scaleEffect(goalBannerDidAppear ? 1 : 0.5)
                .opacity(goalBannerDidAppear ? 1 : 0)
                .onAppear {
                    goalBannerDidAppear = false
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                        goalBannerDidAppear = true
                    }
                }
            Text("\(goal.minute)'").font(.title3.bold()).foregroundStyle(Theme.secondaryText)
            Text(isOwnGoalForFavorite ? "Your side scores — how do you react?" : "They've scored — how do you react?")
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.secondaryText)
        }
    }

    private func isGoalForFavoriteClub(_ goal: GoalEvent) -> Bool {
        guard let favoriteClubId = characterStore.favoriteClub?.id else { return false }
        let scoringClubId = goal.isHomeTeam ? match.homeClubId : match.awayClubId
        return scoringClubId == favoriteClubId
    }

    private func reactionPromptCard(for card: CardEvent) -> some View {
        let isOwnPlayerCarded = isCardOnFavoriteClub(card)
        return VStack(spacing: 16) {
            Image(systemName: "rectangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(card.isRed ? .red : .yellow)
            Text("\(card.isRed ? "RED" : "YELLOW") CARD! \(card.minute)'").font(.title.bold())
            Text("\(card.playerName) (\((card.isHomeTeam ? homeClub?.name : awayClub?.name) ?? "Unknown"))")
                .font(.headline)
                .foregroundStyle(Theme.secondaryText)
            Text(isOwnPlayerCarded ? "One of your side's players is booked — how do you react?" : "A rival gets a card — how do you react?")
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.secondaryText)
        }
    }

    private func isCardOnFavoriteClub(_ card: CardEvent) -> Bool {
        guard let favoriteClubId = characterStore.favoriteClub?.id else { return false }
        let cardedClubId = card.isHomeTeam ? match.homeClubId : match.awayClubId
        return cardedClubId == favoriteClubId
    }

    private func resolveReaction(_ severity: ReactionSeverity) {
        guard let goal = pendingReactionGoal else { return }
        absorb(characterStore.recordActivity(severity.activityType), source: .reactions)
        reactionSeverities.append(severity)
        acknowledgedGoalIDs.insert(goal.id)
        pendingReactionGoal = nil
        // Celebrating your own side's goal draws no security attention —
        // only reactions to the away team's/rival's moments carry heat.
        if !isGoalForFavoriteClub(goal) {
            applyHeat(severity.heat)
        }
        guard !wasEjected else { return }
        if pyroMoment == .afterGoal, offerPyroPromptIfNeeded() {
            return
        }
        advanceWithinLiveMatch()
    }

    private func resolveCardReaction(_ severity: ReactionSeverity) {
        guard let card = pendingReactionCard else { return }
        absorb(characterStore.recordActivity(severity.activityType), source: .reactions)
        reactionSeverities.append(severity)
        acknowledgedCardIDs.insert(card.id)
        pendingReactionCard = nil
        // Same exemption as goals — reacting to your own side's moment
        // (even a card against your own player) draws no heat.
        if !isCardOnFavoriteClub(card) {
            applyHeat(severity.heat)
        }
        if !wasEjected {
            advanceWithinLiveMatch()
        }
    }

    // MARK: - Pyro moment

    private var pyroPromptCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "flame.fill").font(.system(size: 48)).foregroundStyle(.orange)
            Text("Light the Pyro?").font(.title2.bold())
            Text(pyroPromptBodyText).multilineTextAlignment(.center).foregroundStyle(Theme.secondaryText)
        }
    }

    private var pyroPromptBodyText: String {
        guard currentMinute < MatchDayContentPlanner.matchLengthMinutes else {
            return "You never got your planned moment — light it now before the final whistle, or leave it unused?"
        }
        switch pyroMoment {
        case .kickoff: return "Right at kickoff, like you planned — light it now?"
        case .afterGoal: return "The goal's in — light it now like you planned?"
        }
    }

    /// Sets `pendingPyroPrompt` if this is the first (and only) opportunity
    /// to light the pyro under the player's chosen `pyroMoment`, and
    /// returns whether it did — lets a caller skip its usual "advance"
    /// logic in favor of showing this prompt instead.
    @discardableResult
    private func offerPyroPromptIfNeeded() -> Bool {
        guard effectiveHasPyro, !didOfferPyroPrompt, !pendingPyroPrompt else { return false }
        pendingPyroPrompt = true
        return true
    }

    private func resolvePyroPrompt(lightIt: Bool) {
        guard pendingPyroPrompt else { return }
        pendingPyroPrompt = false
        didOfferPyroPrompt = true
        if lightIt {
            didLightPyro = true
            absorb(characterStore.recordActivity(.doPyroChallenge), source: .pyro)
            characterStore.completeTask("light-it-up")
        }
        if !wasEjected {
            advanceWithinLiveMatch()
        }
    }

    /// After a goal or card reaction resolves, checks whether another
    /// reaction is waiting at the same minute before falling through to a
    /// stance checkpoint — preserves goal > card > checkpoint priority when
    /// more than one coincides on the same minute.
    private func advanceWithinLiveMatch() {
        if let card = liveCardEvents.first(where: { $0.minute == currentMinute && !acknowledgedCardIDs.contains($0.id) }) {
            pendingReactionCard = card
        } else {
            checkForPendingCheckpoint()
        }
    }

    /// Adds `amount` to the running stadium-security heat total (from a
    /// goal reaction or from keeping up a risky `MatchStance`) and applies
    /// whatever `SecurityIncidentEngine` says that heat now means —
    /// shared by both sources so ejection/ban logic only lives in one place.
    private func applyHeat(_ amount: Int) {
        guard amount != 0 else { return }
        heat += amount
        var generator = SystemRandomNumberGenerator()
        let outcome = SecurityIncidentEngine.resolve(forHeat: heat, using: &generator)
        securityOutcome = outcome
        if case .ejectedWithBan(let days) = outcome {
            characterStore.applyStadiumBan(days: days)
        }
        switch outcome {
        case .noAction, .warned:
            break
        case .ejected, .ejectedWithBan:
            jumpToSummary()
        }
    }

    /// After a goal reaction resolves, checks whether the minute it landed
    /// on is also an unacknowledged stance checkpoint — since the goal
    /// prompt takes priority when both coincide, the checkpoint check-in
    /// only surfaces once the reaction is out of the way. Once the player
    /// has stopped their stance there's nothing left to check in on, so
    /// later checkpoints are silently acknowledged instead of prompting
    /// with no stance to keep up or stop.
    private func checkForPendingCheckpoint() {
        // Last-chance fallback: if the player planned to light pyro after a
        // goal that never came (e.g. a scoreless match), offer it once at
        // full time instead of the opportunity just quietly disappearing.
        if currentMinute == MatchDayContentPlanner.matchLengthMinutes, offerPyroPromptIfNeeded() {
            return
        }
        guard checkpointMinutes.contains(currentMinute), !acknowledgedCheckpoints.contains(currentMinute) else { return }
        guard currentStance != nil else {
            acknowledgedCheckpoints.insert(currentMinute)
            return
        }
        pendingCheckpointMinute = currentMinute
    }

    private func jumpToSummary() {
        if let index = beats.firstIndex(of: .summary) {
            beatIndex = index
        }
    }

    // MARK: - Chant / tifo

    private var chantCard: some View {
        VStack(spacing: 16) {
            PlaceholderArt(
                primaryColorHex: Theme.crewPrimaryHex,
                secondaryColorHex: Theme.crewSecondaryHex,
                symbolName: "music.mic"
            )
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Text("The Crew Breaks Into Song").font(.title2.bold())
            if let chant {
                Text(chant.title).font(.headline).foregroundStyle(Theme.accent)
                Text(chant.lyrics)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.secondaryText)
            }
            if didJoinChant {
                Label("You joined in", systemImage: "checkmark.circle.fill").foregroundStyle(Theme.accent)
            }
        }
    }

    private var tifoCard: some View {
        VStack(spacing: 16) {
            PlaceholderArt(
                primaryColorHex: Theme.crewPrimaryHex,
                secondaryColorHex: Theme.crewSecondaryHex,
                symbolName: "photo.on.rectangle.angled"
            )
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Text("Tifo Display").font(.title2.bold())
            if let tifo {
                Text(tifo.caption).multilineTextAlignment(.center).foregroundStyle(Theme.secondaryText)
            }
            if didContributeTifo {
                Label("You helped raise it", systemImage: "checkmark.circle.fill").foregroundStyle(Theme.accent)
            }
        }
    }

    // MARK: - Summary

    private var summaryCard: some View {
        ScrollView {
            VStack(spacing: 16) {
                if wasPoliceIntervened {
                    Image(systemName: "exclamationmark.shield.fill").font(.system(size: 48)).foregroundStyle(.red)
                    Text("Pulled Aside By Police").font(.title.bold())
                    Text(policeInterventionSummaryText).multilineTextAlignment(.center).foregroundStyle(Theme.secondaryText)
                } else if wasEjected {
                    Image(systemName: "hand.raised.fill").font(.system(size: 48)).foregroundStyle(.red)
                    Text("Thrown Out").font(.title.bold())
                    Text(ejectionSummaryText).multilineTextAlignment(.center).foregroundStyle(Theme.secondaryText)
                } else {
                    Image(systemName: "sportscourt.fill").font(.system(size: 48)).foregroundStyle(Theme.accent)
                    Text("Full Time").font(.title.bold())
                    Text(summary.displayText).multilineTextAlignment(.center).foregroundStyle(Theme.secondaryText)
                    xpBreakdownCard
                    statDeltaBreakdown
                    if let matchStats {
                        MatchStatsCard(
                            stats: matchStats,
                            homeName: homeClub?.name ?? match.homeClubId,
                            awayName: awayClub?.name ?? match.awayClubId
                        )
                    }
                }

                // The Done (and, on a clean match, "Watch Ad to Double XP")
                // button lives inside the scrollable content itself rather
                // than as a separate fixed action button below it — a
                // fixed button outside this ScrollView was getting pushed
                // off-screen by the ScrollView's own layout instead of
                // actually being constrained to scroll within the
                // remaining space, so it was unreachable on a tall summary.
                // Living inside the scroll content guarantees it's always
                // reachable by scrolling, full stop.
                if !wasPoliceIntervened, !wasEjected, !didDoubleXP, !characterStore.hasRemovedAds, totalXP > 0 {
                    Button {
                        rewardedAdCoordinator.show { [totalXP] in
                            let bonus = characterStore.grantBonusXP(totalXP)
                            guard bonus > 0 else { return }
                            self.totalXP += bonus
                            xpBySource[.adBonus, default: 0] += bonus
                            didDoubleXP = true
                        }
                    } label: {
                        Text("Watch Ad to Double XP (+\(totalXP))")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(Theme.primaryText)
                    }
                    .disabled(!rewardedAdCoordinator.isReady)
                    .opacity(rewardedAdCoordinator.isReady ? 1 : 0.5)
                }

                Button {
                    dismiss()
                } label: {
                    cutsceneButtonLabel("Done")
                }
            }
            .padding(.bottom, 8)
        }
        .task {
            guard !didApplyMatchWrapUp, !wasPoliceIntervened, !wasEjected else { return }
            didApplyMatchWrapUp = true
            guard wasLowInvolvement else { return }
            let penalty = characterStore.applyLowInvolvementPenalty()
            guard penalty > 0 else { return }
            totalXP -= penalty
            xpBySource[.involvement, default: 0] -= penalty
        }
        .task {
            guard !didCheckInterstitial, !wasPoliceIntervened, !wasEjected, !characterStore.hasRemovedAds else { return }
            didCheckInterstitial = true
            guard AdsManager.shouldShowInterstitialAfterMatch() else { return }
            await interstitialAdCoordinator.load()
            interstitialAdCoordinator.showIfReady()
        }
        .task {
            guard !wasPoliceIntervened, !wasEjected, !characterStore.hasRemovedAds else { return }
            await rewardedAdCoordinator.load()
        }
    }

    /// True when the player barely engaged this match: every reaction they
    /// gave was Mild, they never kept a supporting style going, and — if
    /// they brought pyro — they never lit it. All three at once is a
    /// deliberately high bar, so this stays a rare, noticeable penalty
    /// rather than a constant nag. Applied once, at full time, by
    /// `summaryCard`'s `.task`.
    private var wasLowInvolvement: Bool {
        guard !reactionSeverities.isEmpty else { return false }
        let allMild = reactionSeverities.allSatisfy { $0 == .mild }
        let neverSustainedStance = currentStance == nil
        let skippedPyroIfBrought = effectiveHasPyro ? !didLightPyro : true
        return allMild && neverSustainedStance && skippedPyroIfBrought
    }

    /// One row of the XP breakdown — wraps a source+amount pair as
    /// `Identifiable` so `ForEach` doesn't need a tuple key path.
    private struct XPChartEntry: Identifiable {
        let source: XPSource
        let amount: Int
        var id: XPSource { source }
    }

    /// A bar breakdown of this match's XP, grouped by where it came from —
    /// hand-rolled (rather than Swift Charts) to match `MatchStatsCard`'s
    /// existing custom-bar style and avoid pulling in a heavier framework
    /// for a single-series breakdown.
    private var xpBreakdownCard: some View {
        let entries = XPSource.allCases.compactMap { source -> XPChartEntry? in
            let value = xpBySource[source] ?? 0
            return value == 0 ? nil : XPChartEntry(source: source, amount: value)
        }
        let maxMagnitude = entries.map { abs($0.amount) }.max() ?? 0
        return VStack(alignment: .leading, spacing: 8) {
            Text("XP Breakdown").font(.caption.bold()).foregroundStyle(Theme.secondaryText)
            if entries.isEmpty {
                Text("No XP earned this match.").font(.caption).foregroundStyle(Theme.secondaryText)
            } else {
                VStack(spacing: 10) {
                    ForEach(entries) { entry in
                        XPBarRow(label: entry.source.rawValue, amount: entry.amount, maxMagnitude: maxMagnitude)
                    }
                }
            }
        }
        .padding(16)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    /// The Loyalty/Knowledge/Influence/Notoriety this match earned (or, for
    /// Notoriety on a quiet match, didn't) — shown alongside the XP
    /// breakdown on the full-time summary.
    private var statDeltaBreakdown: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Stats This Match").font(.caption.bold()).foregroundStyle(Theme.secondaryText)
            statDeltaRow(label: "Loyalty", delta: loyaltyDelta)
            statDeltaRow(label: "Knowledge", delta: knowledgeDelta)
            statDeltaRow(label: "Influence", delta: influenceDelta)
            statDeltaRow(label: "Notoriety", delta: notorietyDelta)
        }
        .padding(16)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    private func statDeltaRow(label: String, delta: Int) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(Theme.secondaryText)
            Spacer()
            Text(delta >= 0 ? "+\(delta)" : "\(delta)")
                .font(.subheadline.bold())
                .foregroundStyle(delta >= 0 ? Theme.accent : Color.red)
        }
    }

    /// One proportional bar in `xpBreakdownCard`, sized relative to
    /// `maxMagnitude` (the largest absolute XP value across all sources) so
    /// every row's bar is comparable at a glance.
    private struct XPBarRow: View {
        let label: String
        let amount: Int
        let maxMagnitude: Int

        private var barFraction: CGFloat {
            guard maxMagnitude > 0 else { return 0 }
            return CGFloat(abs(amount)) / CGFloat(maxMagnitude)
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(label).font(.caption).foregroundStyle(Theme.secondaryText)
                    Spacer()
                    Text(amount >= 0 ? "+\(amount)" : "\(amount)")
                        .font(.caption.bold())
                        .foregroundStyle(amount >= 0 ? Theme.accent : Color.red)
                }
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(amount >= 0 ? Theme.accent : Color.red)
                        .frame(width: geometry.size.width * barFraction, height: 8)
                }
                .frame(height: 8)
            }
        }
    }

    private var policeInterventionSummaryText: String {
        [
            "Police pulled you aside before you even got through the gate — you never made it in to watch this one.",
            "+\(totalXP) XP before it kicked off",
            "Banned from attending any match for \(UltraViolenceEngine.policeBanDurationDays) days.",
        ].joined(separator: "\n")
    }

    private var ejectionSummaryText: String {
        var lines = [
            "Security pulled you out of the crowd and threw you out of the ground.",
            "+\(totalXP) XP before you were ejected",
        ]
        if case .ejectedWithBan(let days) = securityOutcome {
            lines.append("Banned from attending any match for \(days) days.")
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Action button

    @ViewBuilder
    private var actionButton: some View {
        switch currentBeat {
        case .confrontation where ultraViolenceIncident == nil:
            VStack(spacing: 8) {
                Button {
                    resolveUltraViolence(role: .instigator)
                } label: {
                    cutsceneButtonLabel(
                        characterStore.canInstigateUltraViolence
                            ? "Start Something"
                            : "Start Something (Lead Ultra+ only)"
                    )
                }
                .disabled(!characterStore.canInstigateUltraViolence)
                .opacity(characterStore.canInstigateUltraViolence ? 1 : 0.5)

                Button {
                    resolveUltraViolence(role: .participant)
                } label: {
                    cutsceneButtonLabel("Get Involved")
                }

                Button {
                    beatIndex += 1
                } label: {
                    Text("Stay Out of It")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
        case .security where !securitySearchResolved:
            Button {
                var generator = SystemRandomNumberGenerator()
                let gotThrough = SecurityCheckEngine.resolvePyroSearch(spot: selectedHidingSpot, using: &generator)
                pyroConfiscated = !gotThrough
                securitySearchResolved = true
            } label: {
                cutsceneButtonLabel("Go Through Security")
            }
        case .liveMatch where pendingReactionGoal != nil:
            VStack(spacing: 8) {
                ForEach(ReactionSeverity.allCases, id: \.self) { severity in
                    Button {
                        resolveReaction(severity)
                    } label: {
                        cutsceneButtonLabel("\(severity.displayName) Reaction")
                    }
                }
            }
        case .liveMatch where pendingReactionCard != nil:
            VStack(spacing: 8) {
                ForEach(ReactionSeverity.allCases, id: \.self) { severity in
                    Button {
                        resolveCardReaction(severity)
                    } label: {
                        cutsceneButtonLabel("\(severity.displayName) Reaction")
                    }
                }
            }
        case .liveMatch where pendingPyroPrompt:
            VStack(spacing: 8) {
                Button {
                    resolvePyroPrompt(lightIt: true)
                } label: {
                    cutsceneButtonLabel("Light It Now")
                }
                Button {
                    resolvePyroPrompt(lightIt: false)
                } label: {
                    Text("Not Yet").font(.subheadline).foregroundStyle(Theme.secondaryText)
                }
            }
        case .liveMatch where pendingCheckpointMinute != nil:
            VStack(spacing: 8) {
                if let currentStance {
                    Button {
                        resolveCheckpoint(keepGoing: true)
                    } label: {
                        cutsceneButtonLabel("Keep \(currentStance.displayName)")
                    }
                    Button {
                        resolveCheckpoint(keepGoing: false)
                    } label: {
                        Text("Stop For Now")
                            .font(.subheadline)
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
            }
        case .liveMatch where !currentMatchState.isPlayed:
            Button {
                characterStore.simulateForward(to: match.date)
            } label: {
                cutsceneButtonLabel("Fast Forward to Kickoff")
            }
        case .liveMatch where currentStance == nil && currentMinute == 0 && currentMatchState.isPlayed:
            VStack(spacing: 8) {
                ForEach(MatchStance.allCases, id: \.self) { stance in
                    Button {
                        currentStance = stance
                    } label: {
                        cutsceneButtonLabel(stance.displayName)
                    }
                }
            }
        case .liveMatch where currentMinute < MatchDayContentPlanner.matchLengthMinutes:
            // The clock is ticking on its own (see `advanceClockTick`) — no
            // button needed while play is underway, just a speed control.
            matchSpeedPicker
        case .chant where !didJoinChant:
            Button {
                absorb(characterStore.recordActivity(.participateInChant), source: .chantAndTifo)
                didJoinChant = true
                characterStore.completeTask("learn-a-chant")
            } label: {
                cutsceneButtonLabel("Join the Chant")
            }
        case .tifo where !didContributeTifo:
            Button {
                absorb(characterStore.recordActivity(.contributeToTifo), source: .chantAndTifo)
                didContributeTifo = true
                characterStore.completeTask("help-make-a-tifo")
            } label: {
                cutsceneButtonLabel("Help Raise the Tifo")
            }
        case .summary:
            // The Done/"Watch Ad to Double XP" buttons live inside
            // summaryCard's own scrollable content now (see there for why)
            // — nothing to show in the fixed action-button slot.
            EmptyView()
        default:
            Button {
                beatIndex += 1
            } label: {
                cutsceneButtonLabel("Continue")
            }
        }
    }

    private func cutsceneButtonLabel(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(Theme.accentForeground)
    }

    /// Lets the player speed up (or return to normal) the live-match
    /// clock's real-time ticking — shown in place of an action button
    /// while play is underway, since there's nothing to tap otherwise.
    private var matchSpeedPicker: some View {
        HStack(spacing: 8) {
            ForEach(MatchSpeed.allCases, id: \.self) { speed in
                Button {
                    matchSpeed = speed
                } label: {
                    Text(speed.displayName)
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            matchSpeed == speed ? Theme.accent : Theme.cardBackground,
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                        .foregroundStyle(matchSpeed == speed ? Theme.accentForeground : Theme.primaryText)
                }
            }
        }
    }

    // MARK: - Recording

    private func recordBaseActivities() {
        absorb(characterStore.recordActivity(
            .attendMatch, matchId: match.id, satInUltrasStand: satInUltrasStand, didPyro: effectiveHasPyro
        ), source: .attendance)
        if satInUltrasStand {
            absorb(characterStore.recordActivity(.sitInUltrasStand), source: .attendance)
        }
        // .doPyroChallenge is no longer automatic here — it's only earned
        // when the player actually confirms lighting the pyro at their
        // chosen moment, see `resolvePyroPrompt`.
        if characterStore.isFriendClub(match.homeClubId) || characterStore.isFriendClub(match.awayClubId) {
            absorb(characterStore.recordActivity(.attendFriendClubMatch), source: .attendance)
        }
        // travelMode is only ever set for a fixture where the favorite
        // club is playing away — see where this view is launched.
        if travelMode != nil {
            characterStore.completeTask("travel-to-an-away-game")
        }
    }

    /// Tallies one activity's outcome into the running totals shown on the
    /// full-time summary — `source` buckets its XP for the post-match chart
    /// (see `XPSource`), and its per-stat deltas feed the Loyalty/Knowledge/
    /// Influence/Notoriety breakdown shown after the player taps Continue.
    private func absorb(_ outcome: ActivityOutcomeSummary?, source: XPSource) {
        guard let outcome else { return }
        totalXP += outcome.xpAwarded
        xpBySource[source, default: 0] += outcome.xpAwarded
        loyaltyDelta += outcome.loyaltyDelta
        knowledgeDelta += outcome.knowledgeDelta
        influenceDelta += outcome.influenceDelta
        notorietyDelta += outcome.notorietyDelta
        achievements += outcome.newlyUnlockedAchievements
        items += outcome.newlyUnlockedItems
        membershipAnnouncement = outcome.membershipAnnouncement ?? membershipAnnouncement
        seasonTicketAnnouncement = outcome.seasonTicketAnnouncement ?? seasonTicketAnnouncement
    }

    /// A stylized pitch shown above the scoreline while the match is
    /// live, in the spirit of an old-school 2D match engine: 11
    /// player-position dots per side whose team shape pushes forward or
    /// drops back as a slow "which side currently has it" swing plays out,
    /// all reacting to a single ball marker that drives back and forth
    /// across the pitch. None of this reads the real simulated match
    /// result (there are no real player positions to tie it to, and
    /// nothing here affects the score) — it's a believable animated
    /// backdrop, not a physics/AI engine, tinted in each club's own kit
    /// colors. Many real club pairings share a primary color (e.g. two
    /// clubs both playing in red), so the away side always renders as a
    /// reversed/"away kit" marker — light fill, colored ring — rather than
    /// relying on hue alone to tell the sides apart.
    private struct LiveMatchPitchView: View {
        let homeColorHex: String
        let awayColorHex: String

        /// Relative (x, y) formation slot plus a 0...1 "attacking line"
        /// weight for one team, in its own half (x in 0...1 of that
        /// half's width): goalkeeper (weight 0, barely moves), back four,
        /// midfield four, front two — mirrored horizontally for the away
        /// side. Higher-weight lines shift further when their team is on
        /// the front foot and react more to the ball's position.
        private static let formationSlots: [(x: Double, y: Double, weight: Double)] = [
            (0.08, 0.5, 0.0),
            (0.28, 0.12, 0.3), (0.28, 0.37, 0.3), (0.28, 0.63, 0.3), (0.28, 0.88, 0.3),
            (0.58, 0.08, 0.55), (0.58, 0.33, 0.55), (0.58, 0.67, 0.55), (0.58, 0.92, 0.55),
            (0.85, 0.3, 0.8), (0.85, 0.7, 0.8),
        ]

        var body: some View {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                // A slow -1...1 swing standing in for "who currently has
                // the run of play" — positive means the home side is
                // pushing forward (so the ball trends toward the away
                // goal), negative means the away side is.
                let momentum = sin(t * 0.12)
                let ballX = 0.5 + momentum * 0.38 + sin(t * 0.9) * 0.05
                let ballY = 0.5 + cos(t * 0.53) * 0.33

                GeometryReader { geometry in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    ZStack {
                        LinearGradient(
                            colors: [Color(hex: homeColorHex).opacity(0.55), Color(hex: awayColorHex).opacity(0.55)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        Color.black.opacity(0.25)

                        Rectangle()
                            .strokeBorder(Color.white.opacity(0.6), lineWidth: 1.5)
                            .padding(10)

                        Path { path in
                            path.move(to: CGPoint(x: width / 2, y: 10))
                            path.addLine(to: CGPoint(x: width / 2, y: height - 10))
                        }
                        .stroke(Color.white.opacity(0.6), lineWidth: 1.5)

                        Circle()
                            .stroke(Color.white.opacity(0.6), lineWidth: 1.5)
                            .frame(width: height * 0.55, height: height * 0.55)

                        ForEach(Array(Self.formationSlots.enumerated()), id: \.offset) { index, slot in
                            playerDot(isHome: true, teamColor: Color(hex: homeColorHex), index: index, slot: slot, width: width, height: height, t: t, momentum: momentum, ballY: ballY)
                            playerDot(isHome: false, teamColor: Color(hex: awayColorHex), index: index + Self.formationSlots.count, slot: slot, width: width, height: height, t: t, momentum: momentum, ballY: ballY)
                        }

                        ballDot(width: width, height: height, ballX: ballX, ballY: ballY, t: t)
                    }
                }
            }
            .frame(height: 130)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }

        /// One team's player marker: its formation slot shifted toward the
        /// opponent's goal when `momentum` favors this team (and pulled
        /// back when it doesn't), nudged toward the ball's height, plus a
        /// touch of individual jitter so the pitch feels alive. The home
        /// side renders as a solid-filled dot in its own color; the away
        /// side renders as a light dot ringed in its color — an "away
        /// kit" look that stays readable even when both clubs' primary
        /// colors are nearly identical.
        private func playerDot(isHome: Bool, teamColor: Color, index: Int, slot: (x: Double, y: Double, weight: Double), width: CGFloat, height: CGFloat, t: Double, momentum: Double, ballY: Double) -> some View {
            let baseX = isHome ? slot.x : (1 - slot.x)
            let attackDirection = isHome ? 1.0 : -1.0
            let isAttacking = isHome ? momentum > 0 : momentum < 0
            let shiftAmount = (isAttacking ? 0.22 : -0.12) * slot.weight * abs(momentum)
            let pullTowardBallY = 0.12 + slot.weight * 0.18

            let phase = Double(index) * 1.7
            let jitterX = sin(t * 0.8 + phase) * 0.012
            let jitterY = cos(t * 0.7 + phase * 1.3) * 0.018

            let targetX = baseX + attackDirection * shiftAmount + jitterX
            let targetY = slot.y + (ballY - slot.y) * pullTowardBallY + jitterY

            let x = min(max(targetX, 0.03), 0.97) * width
            let y = min(max(targetY, 0.05), 0.95) * height

            return Group {
                if isHome {
                    Circle()
                        .fill(teamColor)
                        .overlay(Circle().stroke(Color.white.opacity(0.85), lineWidth: 0.75))
                } else {
                    Circle()
                        .fill(Color.white.opacity(0.92))
                        .overlay(Circle().stroke(teamColor, lineWidth: 1.5))
                }
            }
            .frame(width: 7, height: 7)
            .position(x: x, y: y)
        }

        /// The ball marker, following the same `ballX`/`ballY` the player
        /// dots react to, with a touch of extra high-frequency wiggle for
        /// a "being knocked around" feel.
        private func ballDot(width: CGFloat, height: CGFloat, ballX: Double, ballY: Double, t: Double) -> some View {
            let x = (ballX + sin(t * 3) * 0.012) * width
            let y = (ballY + cos(t * 3.4) * 0.012) * height
            return Circle()
                .fill(Color.white)
                .overlay(Circle().stroke(Color.black.opacity(0.35), lineWidth: 0.5))
                .frame(width: 5, height: 5)
                .position(x: x, y: y)
        }
    }
}
