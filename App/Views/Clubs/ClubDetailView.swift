import SwiftUI
import UltrasEuropaCore

struct ClubDetailView: View {
    let club: Club

    @Environment(ContentStore.self) private var contentStore
    @Environment(CharacterStore.self) private var characterStore

    @State private var showFriendshipAlert = false
    @State private var friendshipAlertTitle = ""
    @State private var friendshipAlertMessage = ""

    private var league: League? { contentStore.repository.league(id: club.leagueId) }
    private var isFavoriteClub: Bool { characterStore.favoriteClub?.id == club.id }
    private var canProposeFriendship: Bool { !isFavoriteClub && characterStore.favoriteClub != nil }

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

                if isFavoriteClub {
                    UltrasGroupStatusCard(
                        clubName: club.name,
                        stage: characterStore.ultrasGroupMembershipStage,
                        loyalty: characterStore.stats.loyalty,
                        seasonTicketThreshold: characterStore.homeSeasonTicketLoyaltyThreshold,
                        hasSeasonTicket: characterStore.hasUltrasSeasonTicket,
                        awayLoyaltyPoints: characterStore.awayLoyaltyPoints,
                        awayTicketThreshold: characterStore.awayTicketGuaranteedThreshold,
                        awayTicketChance: characterStore.awayTicketChance
                    )
                }

                NavigationLink {
                    MatchScheduleView(
                        title: "\(club.name) Fixtures",
                        matches: characterStore.matchesForClub(club.id)
                    )
                } label: {
                    ClubLinkRow(title: "Fixtures & Results", systemImage: "sportscourt.fill")
                }

                if canProposeFriendship {
                    friendshipSection
                }
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle(club.name)
        .navigationBarTitleDisplayMode(.inline)
        .alert(friendshipAlertTitle, isPresented: $showFriendshipAlert) {
            Button("OK") {}
        } message: {
            Text(friendshipAlertMessage)
        }
    }

    // MARK: - Ultras friendship

    private var friendshipSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ultras Friendship").font(.headline)

            if let accepted = characterStore.clubFriendshipAccepted(forClubId: club.id) {
                if accepted {
                    Label("Friends with the \(club.ultrasGroupName)", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(Theme.accent)

                    NavigationLink {
                        ClubFriendChatView(club: club)
                    } label: {
                        ClubLinkRow(title: "Chat with the \(club.ultrasGroupName)", systemImage: "bubble.left.and.bubble.right.fill")
                    }

                    Button {
                        let outcome = characterStore.collaborateWithFriendClub(club)
                        friendshipAlertTitle = "Collaboration"
                        friendshipAlertMessage = outcome?.displayText ?? "You reached out, but nothing came of it this time."
                        showFriendshipAlert = true
                    } label: {
                        Text("Collaborate on a Joint Tifo")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(Theme.accentForeground)
                    }

                    Text("Attending any match involving the \(club.name) also earns a small bonus for showing up in solidarity.")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)
                } else {
                    Label("They turned down the friendship", systemImage: "xmark.seal.fill")
                        .foregroundStyle(Theme.secondaryText)
                }
            } else {
                Text("Chance of acceptance: \(Int((characterStore.clubFriendshipChance(with: club) * 100).rounded()))%")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.accent)
                Text("Propose that your crew and the \(club.ultrasGroupName) become friends — chat, collaborate on displays, and show up for each other's matches.")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)

                Button {
                    let accepted = characterStore.proposeClubFriendship(with: club) ?? false
                    friendshipAlertTitle = accepted ? "Friendship Accepted!" : "Turned Down"
                    friendshipAlertMessage = accepted
                        ? "The \(club.ultrasGroupName) have accepted your proposal."
                        : "The \(club.ultrasGroupName) weren't interested this time."
                    showFriendshipAlert = true
                } label: {
                    Text("Propose Ultras Friendship")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(Theme.accentForeground)
                }
            }
        }
        .padding(16)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
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
