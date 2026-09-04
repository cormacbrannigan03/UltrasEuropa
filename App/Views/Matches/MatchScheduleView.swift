import SwiftUI
import UltrasEuropaCore

/// A schedule of fixtures/results — reused both for a whole league's season
/// (from `MatchesHomeView`) and for a single club's fixtures (from
/// `ClubDetailView`), so it just renders whatever `matches` it's given.
struct MatchScheduleView: View {
    let title: String
    let matches: [Match]

    @Environment(ContentStore.self) private var contentStore

    private var sortedMatches: [Match] { matches.sorted { $0.date < $1.date } }
    private var upcoming: [Match] { sortedMatches.filter { !$0.isPlayed } }
    private var results: [Match] { Array(sortedMatches.filter(\.isPlayed).reversed()) }

    var body: some View {
        List {
            Section("Upcoming") {
                if upcoming.isEmpty {
                    Text("No upcoming fixtures.").foregroundStyle(Theme.secondaryText).listRowBackground(Theme.cardBackground)
                }
                ForEach(upcoming) { match in
                    NavigationLink(value: match) { MatchRow(match: match) }
                        .listRowBackground(Theme.cardBackground)
                }
            }
            Section("Results") {
                if results.isEmpty {
                    Text("No results yet.").foregroundStyle(Theme.secondaryText).listRowBackground(Theme.cardBackground)
                }
                ForEach(results) { match in
                    NavigationLink(value: match) { MatchRow(match: match) }
                        .listRowBackground(Theme.cardBackground)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Match.self) { match in
            MatchDetailView(match: match)
        }
    }
}

private struct MatchRow: View {
    let match: Match
    @Environment(ContentStore.self) private var contentStore

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(clubName(match.homeClubId)) vs \(clubName(match.awayClubId))").font(.subheadline.bold())
                Text(match.competition).font(.caption).foregroundStyle(Theme.secondaryText)
            }
            Spacer()
            if match.isPlayed, let h = match.homeScore, let a = match.awayScore {
                Text("\(h) - \(a)").font(.headline)
            } else {
                Text(match.date, style: .date).font(.caption).foregroundStyle(Theme.secondaryText)
            }
        }
    }

    private func clubName(_ id: String) -> String {
        contentStore.repository.club(id: id)?.name ?? id
    }
}
