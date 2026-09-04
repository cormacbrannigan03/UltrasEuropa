import SwiftUI
import UltrasEuropaCore

struct DashboardView: View {
    @Environment(CharacterStore.self) private var characterStore
    @Environment(ContentStore.self) private var contentStore

    private var favoriteClub: Club? {
        guard let id = characterStore.character?.favoriteClubId else { return nil }
        return contentStore.repository.club(id: id)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                RankProgressCard(
                    rank: characterStore.rank,
                    progress: characterStore.nextRankProgress,
                    xpMultiplier: characterStore.favoriteClubXPMultiplier,
                    achievementName: { id in contentStore.repository.achievement(id: id)?.name ?? id }
                )

                StatsGridView(stats: characterStore.stats)

                NavigationLink { InventoryView() } label: {
                    DashboardLinkRow(
                        title: "Inventory", subtitle: "\(characterStore.ownedItems.count) items",
                        systemImage: "bag.fill"
                    )
                }
                NavigationLink { AchievementsView() } label: {
                    DashboardLinkRow(
                        title: "Achievements", subtitle: "\(characterStore.unlockedAchievements.count) unlocked",
                        systemImage: "rosette"
                    )
                }
                NavigationLink { ChallengesListView() } label: {
                    DashboardLinkRow(title: "Challenges", subtitle: "Tasks to complete", systemImage: "checklist")
                }
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("Dashboard")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(characterStore.character?.name ?? "Fan")
                .font(.largeTitle.bold())
            if let crewName = characterStore.character?.crewName, !crewName.isEmpty {
                Text(crewName)
                    .font(.subheadline.bold())
                    .foregroundStyle(Theme.accent)
            }
            if let favoriteClub {
                Text("Follows \(favoriteClub.name)")
                    .foregroundStyle(Theme.secondaryText)
            }
            RankBadge(rank: characterStore.rank)
        }
    }
}

private struct DashboardLinkRow: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack {
            Image(systemName: systemImage).foregroundStyle(Theme.accent).frame(width: 28)
            VStack(alignment: .leading) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(Theme.secondaryText)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(Theme.secondaryText)
        }
        .padding(12)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
        .foregroundStyle(Theme.primaryText)
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
    .environment(PreviewSampleData.characterStore)
    .environment(PreviewSampleData.contentStore)
    .preferredColorScheme(.dark)
}
