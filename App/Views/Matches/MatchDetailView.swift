import SwiftUI
import UltrasEuropaCore

/// How this match relates to the character's favorite club — drives which
/// attendance flow is shown.
private enum MatchContext {
    case favoriteHome
    case favoriteAway
    case neutral
}

struct MatchDetailView: View {
    let match: Match

    @Environment(CharacterStore.self) private var characterStore
    @Environment(ContentStore.self) private var contentStore

    @State private var travelMode: TravelMode = .bus
    @State private var satInUltrasStand = false
    @State private var didPyro = false
    @State private var showCutscene = false
    @State private var showStadiumMap = false

    private var homeClub: Club? { contentStore.repository.club(id: match.homeClubId) }
    private var awayClub: Club? { contentStore.repository.club(id: match.awayClubId) }
    private var alreadyAttended: Bool { characterStore.hasAttended(matchId: match.id) }
    private var ticketsAreOnSale: Bool { characterStore.ticketsAreOnSale(for: match) }

    private var context: MatchContext {
        guard let favoriteClub = characterStore.favoriteClub else { return .neutral }
        if match.homeClubId == favoriteClub.id { return .favoriteHome }
        if match.awayClubId == favoriteClub.id { return .favoriteAway }
        return .neutral
    }

    private var crewFlavorMembers: [CrewMember] {
        let sorted = contentStore.repository.crewMembers.sorted {
            characterStore.bondScore(forMember: $0.id) > characterStore.bondScore(forMember: $1.id)
        }
        return Array(sorted.prefix(2))
    }

    private var matchCategory: MatchCategory { characterStore.matchCategory(for: match) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(spacing: 8) {
                    Text("\(homeClub?.name ?? match.homeClubId) vs \(awayClub?.name ?? match.awayClubId)")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                    Text(match.competition).foregroundStyle(Theme.secondaryText)
                    Text(match.venue).foregroundStyle(Theme.secondaryText)
                    Text(match.date, style: .date).foregroundStyle(Theme.secondaryText)
                    Text("\(matchCategory.displayName) — \(matchCategory.policePresenceDescription)")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)
                    if match.isPlayed, let h = match.homeScore, let a = match.awayScore {
                        Text("\(h) - \(a)").font(.largeTitle.bold())
                    }
                }
                .frame(maxWidth: .infinity)

                if alreadyAttended {
                    Label("You attended this match", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(Theme.accent)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                } else if characterStore.isBannedFromStadium {
                    stadiumBanCard
                } else if !ticketsAreOnSale {
                    ticketsNotYetOnSaleCard
                } else {
                    switch context {
                    case .favoriteHome:
                        homeAttendanceSection
                    case .favoriteAway:
                        awayAttendanceSection
                    case .neutral:
                        neutralAttendanceSection
                    }
                }
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("Match")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showCutscene) {
            MatchDayCutsceneView(
                match: match,
                homeClub: homeClub,
                awayClub: awayClub,
                travelMode: context == .favoriteAway ? travelMode : nil,
                satInUltrasStand: satInUltrasStand,
                didPyro: didPyro
            )
        }
    }

    // MARK: - Stadium ban

    private var stadiumBanCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Banned from the Stadium", systemImage: "nosign")
                .font(.headline)
                .foregroundStyle(.red)
            if let banUntil = characterStore.stadiumBanUntilDate {
                Text("Security threw you out and banned you until \(banUntil, style: .date). Simulate forward to serve it out.")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Tickets not yet on sale

    private var ticketsNotYetOnSaleCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Tickets Not Yet On Sale", systemImage: "lock.fill")
                .font(.headline)
                .foregroundStyle(Theme.secondaryText)
            Text("Tickets for this match go on sale on \(characterStore.ticketSaleDate(for: match), style: .date).")
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Home game: pick a seat

    private var homeAttendanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pick Your Seat").font(.headline)

            if let grantedSeat = characterStore.grantedHomeSeat(forMatchId: match.id) {
                Label("You've got a ticket in the \(grantedSeat.displayName)!", systemImage: "checkmark.seal.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(Theme.accent)

                if grantedSeat == .ultrasSection {
                    Toggle("Do Pyro", isOn: $didPyro)
                }

                Button {
                    satInUltrasStand = grantedSeat == .ultrasSection
                    showCutscene = true
                } label: {
                    ConfirmButtonLabel(text: "Head to the Match")
                }
            } else {
                let tried = characterStore.homeSeatRequests(forMatchId: match.id)
                if !tried.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(tried, id: \.seat) { entry in
                            Text("Denied for the \(entry.seat.displayName) — try a different section.")
                                .font(.caption)
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                }

                Text("Open the stadium map to apply for a section. The Ultras Section is by far the most contested.")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)

                Button {
                    showStadiumMap = true
                } label: {
                    ConfirmButtonLabel(text: "Open Stadium Map")
                }

                if !characterStore.hasUltrasSeasonTicket {
                    let threshold = characterStore.homeSeasonTicketLoyaltyThreshold
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ultras Section season ticket: \(characterStore.stats.loyalty)/\(threshold) loyalty")
                            .font(.caption).foregroundStyle(Theme.secondaryText)
                        ProgressView(value: Double(characterStore.stats.loyalty), total: Double(max(threshold, 1)))
                            .tint(Theme.accent)
                    }
                }
            }
        }
        .padding(16)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showStadiumMap) {
            StadiumMapView(
                triedSeats: Dictionary(
                    uniqueKeysWithValues: characterStore.homeSeatRequests(forMatchId: match.id).map { ($0.seat, $0.granted) }
                ),
                chance: { seat in characterStore.homeSeatChance(for: seat) },
                isGuaranteed: { seat in seat == .ultrasSection && characterStore.hasUltrasSeasonTicket },
                onSelect: { seat in
                    characterStore.requestHomeSeat(for: match, seat: seat)
                    showStadiumMap = false
                }
            )
        }
    }

    // MARK: - Away game: request a ticket

    private var awayAttendanceSection: some View {
        Group {
            if let gotTicket = characterStore.awayTicketAttempt(forMatchId: match.id) {
                if gotTicket {
                    awayTicketGrantedSection
                } else {
                    awayTicketDeniedCard
                }
            } else {
                awayTicketRequestSection
            }
        }
    }

    private var awayTicketRequestSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Request an Away Ticket").font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                Text("Chance of getting a ticket: \(Int((characterStore.awayTicketChance * 100).rounded()))%")
                    .font(.subheadline.bold())
                    .foregroundStyle(Theme.accent)
                ProgressView(
                    value: Double(characterStore.awayLoyaltyPoints),
                    total: Double(max(characterStore.awayTicketGuaranteedThreshold, 1))
                )
                .tint(Theme.accent)
                Text("\(characterStore.awayLoyaltyPoints)/\(characterStore.awayTicketGuaranteedThreshold) away loyalty")
                    .font(.caption).foregroundStyle(Theme.secondaryText)
            }

            travelModePicker

            Toggle("Do Pyro", isOn: $didPyro)

            Button {
                characterStore.attemptAwayTicket(for: match, travelMode: travelMode)
            } label: {
                ConfirmButtonLabel(text: "Request Away Ticket")
            }
        }
        .padding(16)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    private var awayTicketGrantedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("You've got a ticket for this game!", systemImage: "checkmark.seal.fill")
                .font(.headline)
                .foregroundStyle(Theme.accent)

            travelModePicker

            Toggle("Do Pyro", isOn: $didPyro)

            Button {
                satInUltrasStand = true
                showCutscene = true
            } label: {
                ConfirmButtonLabel(text: "Head to the Match")
            }
        }
        .padding(16)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    private var awayTicketDeniedCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("No Ticket This Time", systemImage: "xmark.seal.fill")
                .font(.headline)
                .foregroundStyle(Theme.secondaryText)
            Text("You didn't get an away ticket for this match. Keep building away loyalty for the next one.")
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    private var travelModePicker: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Travel By").font(.headline)
            Picker("Travel By", selection: $travelMode) {
                ForEach(TravelMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            ForEach(crewFlavorMembers) { member in
                Text("\(member.name) thinks the \(TravelMode.preferred(byMemberId: member.id).displayName.lowercased()) is the way to go.")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }

    // MARK: - Any other match

    private var neutralAttendanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Attend This Match").font(.headline)
            Toggle("Sit in the Ultras Stand", isOn: $satInUltrasStand)
            Toggle("Do Pyro", isOn: $didPyro)
            Button {
                showCutscene = true
            } label: {
                ConfirmButtonLabel(text: "Head to the Match")
            }
        }
        .padding(16)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct ConfirmButtonLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(Theme.accentForeground)
    }
}

/// Combines the outcomes of everything recorded on one match day — showing
/// up, sitting in the ultras stand, pyro, joining the chant, and (if one
/// was prepared) contributing to a tifo — since each is its own
/// `ActivityOutcomeSummary`. Also doubles as an away-ticket-denied result.
/// Not `private` — `MatchDayCutsceneView` builds and displays these too.
struct AttendanceSummary {
    let xpAwarded: Int
    let didRankUp: Bool
    let newRank: Rank
    let newlyUnlockedAchievements: [Achievement]
    let newlyUnlockedItems: [InventoryItem]
    let membershipAnnouncement: String?
    let seasonTicketAnnouncement: String?
    let ticketDenied: Bool

    var displayText: String {
        if ticketDenied {
            return "No ticket this time — your away loyalty still went up a little. Keep at it!"
        }

        var lines = ["+\(xpAwarded) XP"]
        if didRankUp {
            lines.append("Ranked up to \(newRank.displayName)!")
        }
        if let membershipAnnouncement {
            lines.append(membershipAnnouncement)
        }
        if let seasonTicketAnnouncement {
            lines.append(seasonTicketAnnouncement)
        }
        if !newlyUnlockedAchievements.isEmpty {
            lines.append("Unlocked: " + newlyUnlockedAchievements.map(\.name).joined(separator: ", "))
        }
        if !newlyUnlockedItems.isEmpty {
            lines.append("New item: " + newlyUnlockedItems.map(\.name).joined(separator: ", "))
        }
        return lines.joined(separator: "\n")
    }
}
