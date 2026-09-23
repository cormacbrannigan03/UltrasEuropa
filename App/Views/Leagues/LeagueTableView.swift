import SwiftUI
import UltrasEuropaCore

/// All 20 real top-flight leagues, each drilling into its live standings
/// table — replaces the old standalone Chants tab (chants/tifo now happen
/// at the match itself, via the match-day cutscene, not a browsable menu).
struct LeagueTableView: View {
    @Environment(ContentStore.self) private var contentStore

    private var leagues: [League] {
        contentStore.repository.leagues.sorted { $0.rank < $1.rank }
    }

    var body: some View {
        List(leagues) { league in
            NavigationLink(value: league) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(league.name).font(.headline)
                    Text(league.country).font(.caption).foregroundStyle(Theme.secondaryText)
                }
            }
            .listRowBackground(Theme.cardBackground)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("League Table")
        .navigationDestination(for: League.self) { league in
            LeagueStandingsView(league: league)
        }
    }
}
