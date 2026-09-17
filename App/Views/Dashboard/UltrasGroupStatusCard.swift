import SwiftUI
import UltrasEuropaCore

/// The player's full standing with their favorite club's ultras group:
/// membership stage (derived from rank), home season-ticket progress
/// (loyalty-gated), and away-ticket odds (away-loyalty-gated).
struct UltrasGroupStatusCard: View {
    let clubName: String
    let stage: UltrasGroupMembershipStage
    let loyalty: Int
    let seasonTicketThreshold: Int
    let hasSeasonTicket: Bool
    let awayLoyaltyPoints: Int
    let awayTicketThreshold: Int
    let awayTicketChance: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(clubName) Ultras").font(.headline)
                Text(stage.displayName).font(.subheadline.bold()).foregroundStyle(Theme.accent)
                Text(stage.description).font(.caption).foregroundStyle(Theme.secondaryText)
            }

            Divider().overlay(Theme.secondaryText.opacity(0.3))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Ultras Section Season Ticket").font(.caption.bold())
                    Spacer()
                    if hasSeasonTicket {
                        Label("Earned", systemImage: "checkmark.seal.fill")
                            .font(.caption.bold())
                            .foregroundStyle(Theme.accent)
                    }
                }
                if !hasSeasonTicket {
                    ProgressView(value: Double(loyalty), total: Double(max(seasonTicketThreshold, 1)))
                        .tint(Theme.accent)
                    Text("\(loyalty)/\(seasonTicketThreshold) loyalty").font(.caption).foregroundStyle(Theme.secondaryText)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Away Tickets").font(.caption.bold())
                ProgressView(value: Double(awayLoyaltyPoints), total: Double(max(awayTicketThreshold, 1)))
                    .tint(Theme.accent)
                Text("\(Int((awayTicketChance * 100).rounded()))% chance per match · \(awayLoyaltyPoints)/\(awayTicketThreshold) away loyalty")
                    .font(.caption).foregroundStyle(Theme.secondaryText)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }
}
