import SwiftUI
import UltrasEuropaCore

/// A shared match-report component showing basic stats — possession,
/// shots, shots on target, and corners — side by side for both teams. Used
/// by `MatchDetailView` for any already-played match, and by
/// `MatchDayCutsceneView`'s full-time summary.
struct MatchStatsCard: View {
    let stats: MatchStats
    let homeName: String
    let awayName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Match Stats").font(.headline)
            HStack {
                Text(homeName).font(.caption.bold()).foregroundStyle(Theme.secondaryText)
                Spacer()
                Text(awayName).font(.caption.bold()).foregroundStyle(Theme.secondaryText)
            }
            StatComparisonRow(label: "Possession", homeValue: stats.homePossession, awayValue: stats.awayPossession, isPercentage: true)
            StatComparisonRow(label: "Shots", homeValue: stats.homeShots, awayValue: stats.awayShots)
            StatComparisonRow(label: "Shots on Target", homeValue: stats.homeShotsOnTarget, awayValue: stats.awayShotsOnTarget)
            StatComparisonRow(label: "Corners", homeValue: stats.homeCorners, awayValue: stats.awayCorners)
        }
        .padding(16)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct StatComparisonRow: View {
    let label: String
    let homeValue: Int
    let awayValue: Int
    var isPercentage: Bool = false

    private var total: Double { Double(max(homeValue + awayValue, 1)) }
    private var homeFraction: Double { Double(homeValue) / total }

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(isPercentage ? "\(homeValue)%" : "\(homeValue)").font(.subheadline.bold())
                Spacer()
                Text(label).font(.caption).foregroundStyle(Theme.secondaryText)
                Spacer()
                Text(isPercentage ? "\(awayValue)%" : "\(awayValue)").font(.subheadline.bold())
            }
            GeometryReader { geo in
                HStack(spacing: 2) {
                    Rectangle()
                        .fill(Theme.accent)
                        .frame(width: geo.size.width * homeFraction)
                    Rectangle()
                        .fill(Theme.secondaryText.opacity(0.3))
                }
            }
            .frame(height: 6)
            .clipShape(Capsule())
        }
    }
}
