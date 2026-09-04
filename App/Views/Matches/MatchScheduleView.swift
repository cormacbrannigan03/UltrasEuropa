import SwiftUI
import UltrasEuropaCore

struct MatchScheduleView: View {
    var filterClubId: String? = nil

    @Environment(ContentStore.self) private var contentStore

    private var matches: [Match] {
        let all = contentStore.repository.matches.sorted { $0.date < $1.date }
        guard let filterClubId else { return all }
        return all.filter { $0.homeClubId == filterClubId || $0.awayClubId == filterClubId }
    }

    private var upcoming: [Match] { matches.filter { !$0.isPlayed } }
    private var results: [Match] { Array(matches.filter(\.isPlayed).reversed()) }

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
        .navigationTitle("Matches")
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
