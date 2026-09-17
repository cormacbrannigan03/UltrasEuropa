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

    @State private var selectedSeat: SeatCategory = .mainStand
    @State private var travelMode: TravelMode = .bus
    @State private var satInUltrasStand = false
    @State private var didPyro = false
    @State private var pendingSummary: AttendanceSummary?
    @State private var showOutcome = false

    private var homeClub: Club? { contentStore.repository.club(id: match.homeClubId) }
    private var awayClub: Club? { contentStore.repository.club(id: match.awayClubId) }
    private var alreadyAttended: Bool { characterStore.hasAttended(matchId: match.id) }

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
        .alert("Match", isPresented: $showOutcome, presenting: pendingSummary) { _ in
            Button("OK") { pendingSummary = nil }
        } message: { summary in
            Text(summary.displayText)
        }
    }

    // MARK: - Home game: pick a seat

    private var homeAttendanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pick Your Seat").font(.headline)

            ForEach(SeatCategory.allCases, id: \.self) { seat in
                let isLocked = seat == .ultrasSection && !characterStore.hasUltrasSeasonTicket
                SeatRow(seat: seat, isSelected: selectedSeat == seat, isLocked: isLocked)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard !isLocked else { return }
                        selectedSeat = seat
                        if seat != .ultrasSection { didPyro = false }
                    }
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

            if selectedSeat == .ultrasSection {
                Toggle("Do Pyro", isOn: $didPyro)
            }

            Button {
                satInUltrasStand = selectedSeat == .ultrasSection
                pendingSummary = recordAttendanceActivities(satInUltrasStand: satInUltrasStand, didPyro: didPyro)
                showOutcome = true
            } label: {
                ConfirmButtonLabel(text: "Confirm Attendance")
            }
        }
        .padding(16)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Away game: request a ticket

    private var awayAttendanceSection: some View {
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

            Text("Travel By").font(.headline)
            Picker("Travel By", selection: $travelMode) {
                ForEach(TravelMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(crewFlavorMembers) { member in
                    Text("\(member.name) thinks the \(TravelMode.preferred(byMemberId: member.id).displayName.lowercased()) is the way to go.")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
            }

            Toggle("Do Pyro", isOn: $didPyro)

            Button {
                requestAwayTicket()
            } label: {
                ConfirmButtonLabel(text: "Request Away Ticket")
            }
        }
        .padding(16)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Any other match

    private var neutralAttendanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Attend This Match").font(.headline)
            Toggle("Sit in the Ultras Stand", isOn: $satInUltrasStand)
            Toggle("Do Pyro", isOn: $didPyro)
            Button {
                pendingSummary = recordAttendanceActivities(satInUltrasStand: satInUltrasStand, didPyro: didPyro)
                showOutcome = true
            } label: {
                ConfirmButtonLabel(text: "Confirm Attendance")
            }
        }
        .padding(16)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Shared attendance recording

    /// Records attending this match plus optionally sitting in the ultras
    /// stand and/or doing pyro, aggregating the (up to three) resulting
    /// `ActivityOutcomeSummary` values into one `AttendanceSummary`.
    private func recordAttendanceActivities(satInUltrasStand: Bool, didPyro: Bool) -> AttendanceSummary {
        var totalXP = 0
        var achievements: [Achievement] = []
        var items: [InventoryItem] = []
        var membershipAnnouncement: String?
        var seasonTicketAnnouncement: String?
        let rankBefore = characterStore.rank

        func absorb(_ outcome: ActivityOutcomeSummary) {
            totalXP += outcome.xpAwarded
            achievements += outcome.newlyUnlockedAchievements
            items += outcome.newlyUnlockedItems
            membershipAnnouncement = outcome.membershipAnnouncement ?? membershipAnnouncement
            seasonTicketAnnouncement = outcome.seasonTicketAnnouncement ?? seasonTicketAnnouncement
        }

        if let outcome = characterStore.recordActivity(
            .attendMatch, matchId: match.id, satInUltrasStand: satInUltrasStand, didPyro: didPyro
        ) {
            absorb(outcome)
        }
        if satInUltrasStand, let outcome = characterStore.recordActivity(.sitInUltrasStand) {
            absorb(outcome)
        }
        if didPyro, let outcome = characterStore.recordActivity(.doPyroChallenge) {
            absorb(outcome)
        }

        return AttendanceSummary(
            xpAwarded: totalXP,
            didRankUp: characterStore.rank > rankBefore,
            newRank: characterStore.rank,
            newlyUnlockedAchievements: achievements,
            newlyUnlockedItems: items,
            membershipAnnouncement: membershipAnnouncement,
            seasonTicketAnnouncement: seasonTicketAnnouncement,
            ticketDenied: false
        )
    }

    private func requestAwayTicket() {
        guard let gotTicket = characterStore.attemptAwayTicket(for: match, travelMode: travelMode) else { return }
        if gotTicket {
            // Getting the ticket through the ultras' away allocation means
            // traveling with the group — that's the away-end experience.
            pendingSummary = recordAttendanceActivities(satInUltrasStand: true, didPyro: didPyro)
        } else {
            pendingSummary = AttendanceSummary(
                xpAwarded: 0,
                didRankUp: false,
                newRank: characterStore.rank,
                newlyUnlockedAchievements: [],
                newlyUnlockedItems: [],
                membershipAnnouncement: nil,
                seasonTicketAnnouncement: nil,
                ticketDenied: true
            )
        }
        showOutcome = true
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
            .foregroundStyle(.white)
    }
}

private struct SeatRow: View {
    let seat: SeatCategory
    let isSelected: Bool
    let isLocked: Bool

    var body: some View {
        HStack {
            Image(systemName: isLocked ? "lock.fill" : (isSelected ? "checkmark.circle.fill" : "circle"))
                .foregroundStyle(isLocked ? Theme.secondaryText : Theme.accent)
            Text(seat.displayName)
                .foregroundStyle(isLocked ? Theme.secondaryText : Theme.primaryText)
            Spacer()
        }
        .padding(10)
        .background(Theme.background, in: RoundedRectangle(cornerRadius: 10))
        .opacity(isLocked ? 0.6 : 1)
    }
}

/// Combines the outcomes of up to three activities recorded together when
/// attending a match (attend + optionally sit in the stand + optionally do
/// pyro), since each is its own `ActivityOutcomeSummary` — or represents an
/// away-ticket request that didn't come through.
private struct AttendanceSummary {
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
