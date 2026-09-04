import SwiftUI
import UltrasEuropaCore

/// The clubs within one league.
struct LeagueClubsView: View {
    let league: League

    @Environment(ContentStore.self) private var contentStore

    var body: some View {
        List(contentStore.repository.clubsInLeague(league.id)) { club in
            NavigationLink(value: club) {
                HStack {
                    PlaceholderArt(
                        primaryColorHex: club.primaryColorHex,
                        secondaryColorHex: club.secondaryColorHex,
                        symbolName: "shield.fill"
                    )
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading) {
                        Text(club.name).font(.headline)
                        Text(club.city).font(.caption).foregroundStyle(Theme.secondaryText)
                    }
                }
            }
            .listRowBackground(Theme.cardBackground)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle(league.name)
        .navigationDestination(for: Club.self) { club in
            ClubDetailView(club: club)
        }
    }
}
