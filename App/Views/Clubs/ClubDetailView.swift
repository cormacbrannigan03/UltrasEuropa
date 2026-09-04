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

                PrestigeIndicator(tier: club.prestigeTier)

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

/// Shows a club's prestige tier (1-5) as stars, with a note on what that
/// means for progression — see `ProgressionConstants.xpMultiplier(forPrestigeTier:)`.
struct PrestigeIndicator: View {
    let tier: Int

    private var multiplier: Double { ProgressionConstants.xpMultiplier(forPrestigeTier: tier) }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= tier ? "star.fill" : "star")
                        .foregroundStyle(star <= tier ? Theme.accent : Theme.secondaryText)
                        .font(.caption)
                }
                Text("Prestige").font(.caption).foregroundStyle(Theme.secondaryText).padding(.leading, 4)
            }
            Text("Fans of this club need \(String(format: "%.1f", multiplier))× the base XP to rank up.")
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
        }
        .padding(12)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
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
