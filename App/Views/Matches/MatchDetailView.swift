import SwiftUI
import UltrasEuropaCore

struct MatchDetailView: View {
    let match: Match

    @Environment(CharacterStore.self) private var characterStore
    @Environment(ContentStore.self) private var contentStore

    @State private var satInUltrasStand = false
    @State private var didPyro = false
    @State private var pendingSummary: AttendanceSummary?
    @State private var showOutcome = false

    private var homeClub: Club? { contentStore.repository.club(id: match.homeClubId) }
    private var awayClub: Club? { contentStore.repository.club(id: match.awayClubId) }
    private var alreadyAttended: Bool { characterStore.hasAttended(matchId: match.id) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(spacing: 8) {
                    Text("\(homeClub?.name ?? match.homeClubId) vs \(awayClub?.name ?? match.awayClubId)")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                    Text(match.competition).foregroundStyle(Theme.secondaryText)
                    Text(match.venue).foregroundStyle(Theme.secondaryText)
                    Text(match.date, style: .date).foregroundStyle(Theme.secondaryText)
                    if match.isPlayed, let h = match.homeScore, let a = match.awayScore {
                        Text("\(h) - \(a)").font(.largeTitle.bold())
                    }
                }
                .frame(maxWidth: .infinity)

                if alreadyAttended {
                    Label("You attended this match", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(Theme.accent)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Attend This Match").font(.headline)
                        Toggle("Sit in the Ultras Stand", isOn: $satInUltrasStand)
                        Toggle("Do Pyro", isOn: $didPyro)
                        Button {
                            attend()
                        } label: {
                            Text("Confirm Attendance")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(16)
                    .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("Match")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Match Attended", isPresented: $showOutcome, presenting: pendingSummary) { _ in
            Button("OK") { pendingSummary = nil }
        } message: { summary in
            Text(summary.displayText)
        }
    }

    private func attend() {
        var totalXP = 0
        var achievements: [Achievement] = []
        var items: [InventoryItem] = []
        let rankBefore = characterStore.rank

        if let outcome = characterStore.recordActivity(
            .attendMatch, matchId: match.id, satInUltrasStand: satInUltrasStand, didPyro: didPyro
        ) {
            totalXP += outcome.xpAwarded
            achievements += outcome.newlyUnlockedAchievements
            items += outcome.newlyUnlockedItems
        }
        if satInUltrasStand, let outcome = characterStore.recordActivity(.sitInUltrasStand) {
            totalXP += outcome.xpAwarded
            achievements += outcome.newlyUnlockedAchievements
            items += outcome.newlyUnlockedItems
        }
        if didPyro, let outcome = characterStore.recordActivity(.doPyroChallenge) {
            totalXP += outcome.xpAwarded
            achievements += outcome.newlyUnlockedAchievements
            items += outcome.newlyUnlockedItems
        }

        pendingSummary = AttendanceSummary(
            xpAwarded: totalXP,
            didRankUp: characterStore.rank > rankBefore,
            newRank: characterStore.rank,
            newlyUnlockedAchievements: achievements,
            newlyUnlockedItems: items
        )
        showOutcome = true
    }
}

/// Combines the outcomes of up to three activities recorded together when
/// attending a match (attend + optionally sit in the stand + optionally do
/// pyro), since each is its own `ActivityOutcomeSummary`.
private struct AttendanceSummary {
    let xpAwarded: Int
    let didRankUp: Bool
    let newRank: Rank
    let newlyUnlockedAchievements: [Achievement]
    let newlyUnlockedItems: [InventoryItem]

    var displayText: String {
        var lines = ["+\(xpAwarded) XP"]
        if didRankUp {
            lines.append("Ranked up to \(newRank.displayName)!")
        }
        if !newlyUnlockedAchievements.isEmpty {
            lines.append("Unlocked: " + newlyUnlockedAchievements.map(\.name).joined(separator: ", "))
        }
        if !newlyUnlockedItems.isEmpty {
            lines.append("New item: " + newlyUnlockedItems.map(\.name).joined(separator: ", "))
        }
        return lines.joined(separator: "\n")
    }
}
