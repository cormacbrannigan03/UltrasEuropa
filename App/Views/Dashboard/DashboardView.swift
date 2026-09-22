import SwiftUI
import UltrasEuropaCore

struct DashboardView: View {
    @Environment(CharacterStore.self) private var characterStore
    @Environment(ContentStore.self) private var contentStore
    @Environment(SaveSlotStore.self) private var saveSlotStore

    @State private var showSwitchSaveConfirmation = false

    private var favoriteClub: Club? { characterStore.favoriteClub }
    private var localization: LocalizationManager { LocalizationManager.shared }

    private var nextMatch: Match? { characterStore.nextMatchForFavoriteClub }

    private func isHomeMatch(_ match: Match) -> Bool {
        match.homeClubId == favoriteClub?.id
    }

    private func opponentName(for match: Match) -> String {
        let opponentId = isHomeMatch(match) ? match.awayClubId : match.homeClubId
        return contentStore.repository.club(id: opponentId)?.name ?? opponentId
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                SeasonClockCard(
                    simulatedDate: characterStore.simulatedDate,
                    onSimulateDay: { characterStore.simulateDays(1) },
                    onSimulateWeek: { characterStore.simulateDays(7) }
                )

                if let nextMatch {
                    NextMatchCard(
                        match: nextMatch,
                        isHome: isHomeMatch(nextMatch),
                        opponentName: opponentName(for: nextMatch),
                        isToday: Calendar.current.isDate(nextMatch.date, inSameDayAs: characterStore.simulatedDate)
                    )
                } else if favoriteClub != nil {
                    NoUpcomingMatchCard()
                }

                RankProgressCard(
                    rank: characterStore.rank,
                    progress: characterStore.nextRankProgress,
                    xpMultiplier: characterStore.favoriteClubXPMultiplier,
                    achievementName: { id in contentStore.repository.achievement(id: id)?.name ?? id }
                )

                if let favoriteClub {
                    UltrasGroupStatusCard(
                        clubName: favoriteClub.name,
                        stage: characterStore.ultrasGroupMembershipStage,
                        loyalty: characterStore.stats.loyalty,
                        seasonTicketThreshold: characterStore.homeSeasonTicketLoyaltyThreshold,
                        hasSeasonTicket: characterStore.hasUltrasSeasonTicket,
                        awayLoyaltyPoints: characterStore.awayLoyaltyPoints,
                        awayTicketThreshold: characterStore.awayTicketGuaranteedThreshold,
                        awayTicketChance: characterStore.awayTicketChance
                    )
                }

                StatsGridView(stats: characterStore.stats)

                NavigationLink { SeasonCalendarView() } label: {
                    DashboardLinkRow(title: localization.string(.seasonCalendar), subtitle: "Fast forward to your next match", systemImage: "calendar")
                }
                NavigationLink { CrewMembersView() } label: {
                    DashboardLinkRow(title: "Crew Members", subtitle: "Build relationships", systemImage: "person.3.fill")
                }
                NavigationLink { YouthGroupView() } label: {
                    DashboardLinkRow(
                        title: "Youth Group",
                        subtitle: characterStore.youthGroupFounded
                            ? characterStore.youthGroupStage.displayName
                            : "Start your own following",
                        systemImage: "flag.2.crossed.fill"
                    )
                }
                NavigationLink { WardrobeView() } label: {
                    DashboardLinkRow(title: "Wardrobe", subtitle: "Dress your character", systemImage: "tshirt.fill")
                }
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
                NavigationLink { StoreView() } label: {
                    DashboardLinkRow(title: localization.string(.store), subtitle: "Fast-track your journey", systemImage: "cart.fill")
                }
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("Dashboard")
        .navigationDestination(for: Match.self) { match in
            MatchDetailView(match: match)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    ForEach(AppLanguage.allCases) { language in
                        Button {
                            LocalizationManager.shared.setLanguage(language)
                        } label: {
                            HStack {
                                Text("\(language.flagEmoji) \(language.nativeName)")
                                if language == localization.currentLanguage {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Text(localization.currentLanguage.flagEmoji)
                        .font(.title2)
                }
                .accessibilityLabel(localization.string(.language))
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSwitchSaveConfirmation = true
                } label: {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                }
            }
        }
        .confirmationDialog(
            "Switch Save?",
            isPresented: $showSwitchSaveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Switch Save") { saveSlotStore.clearActiveSlot() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your progress in this save is kept — you can come back to it anytime from the save picker.")
        }
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
    .environment(PreviewSampleData.saveSlotStore)
    .preferredColorScheme(.dark)
}
