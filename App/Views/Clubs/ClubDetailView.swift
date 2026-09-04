import SwiftUI
import UltrasEuropaCore

struct ClubDetailView: View {
    let club: Club

    @Environment(ContentStore.self) private var contentStore

    private var league: League? { contentStore.repository.league(id: club.leagueId) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PlaceholderArt(
                    primaryColorHex: club.primaryColorHex,
                    secondaryColorHex: club.secondaryColorHex,
                    symbolName: "shield.fill",
                    caption: club.name
                )
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 8) {
                    Text(club.name).font(.title.bold())
                    Text("\(club.city), \(club.country) · Founded \(String(club.founded))")
                        .foregroundStyle(Theme.secondaryText)
                    Text(club.stadiumName).foregroundStyle(Theme.secondaryText)
                    if let league {
                        Text(league.name).foregroundStyle(Theme.secondaryText)
                    }
                    if let history = club.history {
                        Text(history).padding(.top, 4)
                    }
                }

                NavigationLink {
                    MatchScheduleView(
                        title: "\(club.name) Fixtures",
                        matches: contentStore.repository.matchesForClub(club.id)
                    )
                } label: {
                    ClubLinkRow(title: "Fixtures & Results", systemImage: "sportscourt.fill")
                }
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle(club.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ClubLinkRow: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack {
            Image(systemName: systemImage).foregroundStyle(Theme.accent).frame(width: 28)
            Text(title).font(.headline)
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(Theme.secondaryText)
        }
        .padding(12)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
        .foregroundStyle(Theme.primaryText)
    }
}
