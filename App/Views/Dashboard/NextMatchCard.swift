import SwiftUI
import UltrasEuropaCore

/// The favorite club's next unplayed fixture, shown right on the
/// Dashboard so there's always a one-tap way to pick up where the season
/// left off — no detour through the Season Calendar required. Tapping it
/// pushes straight to that match's `MatchDetailView`, where attendance,
/// tickets, and (once it's matchday) the cutscene all continue from.
struct NextMatchCard: View {
    let match: Match
    let isHome: Bool
    let opponentName: String
    let isToday: Bool

    var body: some View {
        NavigationLink(value: match) {
            HStack(spacing: 14) {
                Image(systemName: "sportscourt.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.accentForeground)
                    .frame(width: 44, height: 44)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Next Match").font(.caption).foregroundStyle(Theme.secondaryText)
                    Text("\(isHome ? "vs" : "@") \(opponentName)").font(.headline)
                    Text(match.date, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                }

                Spacer()

                if isToday {
                    Text("Today")
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.accent, in: Capsule())
                        .foregroundStyle(Theme.accentForeground)
                }
                Image(systemName: "chevron.right").foregroundStyle(Theme.secondaryText)
            }
            .padding(14)
            .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .foregroundStyle(Theme.primaryText)
    }
}

/// Shown instead of `NextMatchCard` once every fixture for the season has
/// been played — there's nothing left to fast forward to.
struct NoUpcomingMatchCard: View {
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title2)
                .foregroundStyle(Theme.secondaryText)
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 4) {
                Text("Next Match").font(.caption).foregroundStyle(Theme.secondaryText)
                Text("No fixtures left this season").font(.headline)
            }
            Spacer()
        }
        .padding(14)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 14))
    }
}
