import SwiftUI
import UltrasEuropaCore

/// The full-screen "you're at the match" sequence, presented once
/// attendance is locked in (seat picked, away ticket granted, or the
/// neutral toggle confirmed) — arriving (by bus/train first, for an away
/// day), joining in the chant, raising a tifo if one's prepared for this
/// fixture, and a closing summary. This is where `.participateInChant` and
/// `.contributeToTifo` actually get earned now — not a standalone menu
/// button reachable from anywhere, anytime.
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
        case liveMatch
        case chant
        case tifo
        case pyro
        case summary
    }

    @State private var beatIndex = 0
    @State private var didJoinChant = false
    @State private var didContributeTifo = false
    @State private var currentMinute = 0

    @State private var rankBefore: Rank = .regular
    @State private var totalXP = 0
    @State private var achievements: [Achievement] = []
    @State private var items: [InventoryItem] = []
    @State private var membershipAnnouncement: String?
    @State private var seasonTicketAnnouncement: String?

    private var chant: Chant? { contentStore.repository.chantOfTheDay(matchId: match.id) }
    private var tifo: TifoPhoto? { contentStore.repository.preparedTifo(matchId: match.id) }

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

    private var beats: [Beat] {
        var beats: [Beat] = []
        if travelMode != nil { beats.append(.travel) }
        beats.append(.arrival)
        beats.append(.liveMatch)
        beats.append(.chant)
        if tifo != nil { beats.append(.tifo) }
        if didPyro { beats.append(.pyro) }
        beats.append(.summary)
        return beats
    }

    private var currentBeat: Beat {
        let all = beats
        return all.indices.contains(beatIndex) ? all[beatIndex] : .summary
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
        case .liveMatch:
            liveMatchCard
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

    /// Watching the match unfold — if the season clock hasn't reached
    /// kickoff yet, prompts to fast forward instead of showing a
    /// scoreboard; once it has, runs a minute-by-minute clock revealing
    /// `liveGoalEvents` as they occur, ending at the same fixed final
    /// score `SeasonScheduleGenerator` already generated for this match.
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
            guard currentMatchState.isPlayed else { return }
            rankBefore = characterStore.rank
            recordBaseActivities()
            await runMatchClock()
        }
    }

    private func scoreColumn(name: String, goals: Int) -> some View {
        VStack(spacing: 4) {
            Text(name).font(.caption).multilineTextAlignment(.center).foregroundStyle(Theme.secondaryText)
            Text("\(goals)").font(.title.bold())
        }
        .frame(maxWidth: .infinity)
    }

    private func runMatchClock() async {
        for minute in 1...MatchDayContentPlanner.matchLengthMinutes {
            if Task.isCancelled { return }
            try? await Task.sleep(nanoseconds: 150_000_000)
            currentMinute = minute
        }
    }

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

    private var summaryCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "sportscourt.fill")
                .font(.system(size: 48))
                .foregroundStyle(Theme.accent)
            Text("Full Time").font(.title.bold())
            Text(summary.displayText)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.secondaryText)
        }
    }

    // MARK: - Action button

    @ViewBuilder
    private var actionButton: some View {
        switch currentBeat {
        case .liveMatch where !currentMatchState.isPlayed:
            Button {
                characterStore.simulateForward(to: match.date)
            } label: {
                cutsceneButtonLabel("Fast Forward to Kickoff")
            }
        case .liveMatch where currentMinute < MatchDayContentPlanner.matchLengthMinutes:
            Button {
                currentMinute = MatchDayContentPlanner.matchLengthMinutes
            } label: {
                cutsceneButtonLabel("Skip to Full Time")
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
            .foregroundStyle(.white)
    }

    // MARK: - Recording

    private func recordBaseActivities() {
        absorb(characterStore.recordActivity(
            .attendMatch, matchId: match.id, satInUltrasStand: satInUltrasStand, didPyro: didPyro
        ))
        if satInUltrasStand {
            absorb(characterStore.recordActivity(.sitInUltrasStand))
        }
        if didPyro {
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
