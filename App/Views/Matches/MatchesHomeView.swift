import SwiftUI
import UltrasEuropaCore

/// Top of the Matches tab: pick a league, then see its full generated
/// season (see `SeasonScheduleGenerator` — these are not real fixtures).
struct MatchesHomeView: View {
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
        .navigationTitle("Matches")
        .navigationDestination(for: League.self) { league in
            MatchScheduleView(title: league.name, matches: contentStore.repository.matchesInLeague(league.id))
        }
    }
}
