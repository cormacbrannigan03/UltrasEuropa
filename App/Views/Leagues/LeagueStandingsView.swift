import SwiftUI
import UltrasEuropaCore

/// The live table for one league — computed fresh from that league's
/// generated season (see `LeagueTableEngine`), not stored anywhere,
/// consistent with how the fixtures themselves are generated on demand
/// rather than shipped as static data.
struct LeagueStandingsView: View {
    let league: League

    @Environment(ContentStore.self) private var contentStore
    @Environment(CharacterStore.self) private var characterStore

    private var clubs: [Club] { contentStore.repository.clubsInLeague(league.id) }

    private var rows: [LeagueTableRow] {
        let matches = contentStore.repository.matchesInLeague(league.id, asOf: characterStore.simulatedDate)
        return LeagueTableEngine.standings(matches: matches, clubIds: clubs.map(\.id))
    }

    private func club(forId id: String) -> Club? {
        clubs.first { $0.id == id }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 4) {
                header
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    if let club = club(forId: row.clubId) {
                        NavigationLink(value: club) {
                            LeagueTableRowView(
                                position: index + 1, club: club, row: row,
                                isFavoriteClub: club.id == characterStore.favoriteClub?.id
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle(league.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Club.self) { club in
            ClubDetailView(club: club)
        }
    }

    private var header: some View {
        HStack {
            Text("#").frame(width: 22, alignment: .leading)
            Text("Club").frame(maxWidth: .infinity, alignment: .leading)
            Text("P").frame(width: 24)
            Text("W").frame(width: 24)
            Text("D").frame(width: 24)
            Text("L").frame(width: 24)
            Text("GD").frame(width: 32)
            Text("Pts").frame(width: 32)
        }
        .font(.caption2.bold())
        .foregroundStyle(Theme.secondaryText)
        .padding(.horizontal, 8)
    }
}

private struct LeagueTableRowView: View {
    let position: Int
    let club: Club
    let row: LeagueTableRow
    let isFavoriteClub: Bool

    var body: some View {
        HStack {
            Text("\(position)").frame(width: 22, alignment: .leading).font(.caption.bold())
            Text(club.name)
                .font(.caption.bold())
                .foregroundStyle(isFavoriteClub ? Theme.accent : Theme.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
            Text("\(row.played)").frame(width: 24).font(.caption)
            Text("\(row.won)").frame(width: 24).font(.caption)
            Text("\(row.drawn)").frame(width: 24).font(.caption)
            Text("\(row.lost)").frame(width: 24).font(.caption)
            Text("\(row.goalDifference >= 0 ? "+" : "")\(row.goalDifference)").frame(width: 32).font(.caption)
            Text("\(row.points)").frame(width: 32).font(.caption.bold()).foregroundStyle(Theme.accent)
        }
        .foregroundStyle(Theme.primaryText)
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 8))
    }
}
