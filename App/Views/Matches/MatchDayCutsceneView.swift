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

    @Environment(CharacterStore.self) private var characterStore
    @Environment(ContentStore.self) private var contentStore
    @Environment(\.dismiss) private var dismiss

    private enum Beat: Equatable {
        case travel
        case arrival
        case security
        case liveMatch
        case chant
        case tifo
        case pyro
        case summary
    }

    @State private var beatIndex = 0
    @State private var didJoinChant = false
    @State private var didContributeTifo = false

    @State private var selectedHidingSpot: PyroHidingSpot = .insideJacket
    @State private var securitySearchResolved = false
    @State private var pyroConfiscated = false

    @State private var currentMinute = 0
    @State private var acknowledgedGoalIDs: Set<String> = []
    @State private var pendingReactionGoal: GoalEvent?
    @State private var heat = 0
    @State private var securityOutcome: SecurityOutcome = .noAction
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

    /// The minute of the next goal that hasn't had its reaction resolved
    /// yet, or full time if none remain — where "Continue Watching" jumps to.
    private var nextStopMinute: Int {
        liveGoalEvents
            .filter { !acknowledgedGoalIDs.contains($0.id) }
            .map(\.minute)
            .min() ?? MatchDayContentPlanner.matchLengthMinutes
    }

    private var beats: [Beat] {
        var beats: [Beat] = []
        if travelMode != nil { beats.append(.travel) }
        beats.append(.arrival)
        if didPyro { beats.append(.security) }
        beats.append(.liveMatch)
        beats.append(.chant)
        if tifo != nil { beats.append(.tifo) }
        if effectiveHasPyro { beats.append(.pyro) }
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
        case .security:
            securityCard
        case .liveMatch:
            if let pendingReactionGoal {
                reactionPromptCard(for: pendingReactionGoal)
            } else {
                liveMatchCard
            }
        case .chant:
            chantCard
        case .tifo:
            tifoCard
        case .pyro:
            sceneCard(
                symbolName: "flame.fill",
                title: "Pyro",
                body: "Smoke fills the stand as flares go up around you."
            )
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

                VStack(alignment: .leading, spacing: 4) {
                    ForEach(visibleGoalEvents) { event in
                        Text("⚽️ \(event.minute)' — \((event.isHomeTeam ? homeClub?.name : awayClub?.name) ?? "Goal!")")
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
            }
        }
        .task(id: currentMatchState.isPlayed) {
            guard currentMatchState.isPlayed, !didRecordBaseActivities else { return }
            didRecordBaseActivities = true
            rankBefore = characterStore.rank
            recordBaseActivities()
        }
    }

    private func scoreColumn(name: String, goals: Int) -> some View {
        VStack(spacing: 4) {
            Text(name).font(.caption).multilineTextAlignment(.center).foregroundStyle(Theme.secondaryText)
            Text("\(goals)").font(.title.bold())
        }
        .frame(maxWidth: .infinity)
    }

    private func reactionPromptCard(for goal: GoalEvent) -> some View {
        let isOwnGoalForFavorite = isGoalForFavoriteClub(goal)
        return VStack(spacing: 16) {
            Image(systemName: "soccerball")
                .font(.system(size: 48))
                .foregroundStyle(Theme.accent)
            Text("GOAL! \(goal.minute)'").font(.title.bold())
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

    private func resolveReaction(_ severity: ReactionSeverity) {
        guard let goal = pendingReactionGoal else { return }
        absorb(characterStore.recordActivity(severity.activityType))
        acknowledgedGoalIDs.insert(goal.id)
        heat += severity.heat
        pendingReactionGoal = nil

        let outcome = SecurityIncidentEngine.outcome(forHeat: heat)
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
        VStack(spacing: 16) {
            if wasEjected {
                Image(systemName: "hand.raised.fill").font(.system(size: 48)).foregroundStyle(.red)
                Text("Thrown Out").font(.title.bold())
                Text(ejectionSummaryText).multilineTextAlignment(.center).foregroundStyle(Theme.secondaryText)
            } else {
                Image(systemName: "sportscourt.fill").font(.system(size: 48)).foregroundStyle(Theme.accent)
                Text("Full Time").font(.title.bold())
                Text(summary.displayText).multilineTextAlignment(.center).foregroundStyle(Theme.secondaryText)
            }
        }
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
        case .liveMatch where !currentMatchState.isPlayed:
            Button {
                characterStore.simulateForward(to: match.date)
            } label: {
                cutsceneButtonLabel("Fast Forward to Kickoff")
            }
        case .liveMatch where currentMinute < MatchDayContentPlanner.matchLengthMinutes:
            Button {
                withAnimation { currentMinute = nextStopMinute }
                if let goal = liveGoalEvents.first(where: { $0.minute == currentMinute && !acknowledgedGoalIDs.contains($0.id) }) {
                    pendingReactionGoal = goal
                }
            } label: {
                cutsceneButtonLabel(nextStopMinute >= MatchDayContentPlanner.matchLengthMinutes ? "Play to Full Time" : "Continue Watching")
            }
        case .chant where !didJoinChant:
            Button {
                absorb(characterStore.recordActivity(.participateInChant))
                didJoinChant = true
            } label: {
                cutsceneButtonLabel("Join the Chant")
            }
        case .tifo where !didContributeTifo:
            Button {
                absorb(characterStore.recordActivity(.contributeToTifo))
                didContributeTifo = true
            } label: {
                cutsceneButtonLabel("Help Raise the Tifo")
            }
        case .summary:
            Button {
                dismiss()
            } label: {
                cutsceneButtonLabel("Done")
            }
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

    // MARK: - Recording

    private func recordBaseActivities() {
        absorb(characterStore.recordActivity(
            .attendMatch, matchId: match.id, satInUltrasStand: satInUltrasStand, didPyro: effectiveHasPyro
        ))
        if satInUltrasStand {
            absorb(characterStore.recordActivity(.sitInUltrasStand))
        }
        if effectiveHasPyro {
            absorb(characterStore.recordActivity(.doPyroChallenge))
        }
    }

    private func absorb(_ outcome: ActivityOutcomeSummary?) {
        guard let outcome else { return }
        totalXP += outcome.xpAwarded
        achievements += outcome.newlyUnlockedAchievements
        items += outcome.newlyUnlockedItems
        membershipAnnouncement = outcome.membershipAnnouncement ?? membershipAnnouncement
        seasonTicketAnnouncement = outcome.seasonTicketAnnouncement ?? seasonTicketAnnouncement
    }
}
