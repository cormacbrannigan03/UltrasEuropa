import SwiftUI
import UltrasEuropaCore

struct StatsGridView: View {
    let stats: CharacterStats

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            StatTile(label: "Loyalty", value: stats.loyalty, systemImage: "heart.fill")
            StatTile(label: "Knowledge", value: stats.knowledge, systemImage: "book.fill")
            StatTile(label: "Influence", value: stats.influence, systemImage: "megaphone.fill")
            StatTile(label: "Notoriety", value: stats.notoriety, systemImage: "flame.fill")
        }
    }
}

private struct StatTile: View {
    let label: String
    let value: Int
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: systemImage).foregroundStyle(Theme.accent)
            Text("\(value)").font(.title2.bold())
            Text(label).font(.caption).foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }
}
