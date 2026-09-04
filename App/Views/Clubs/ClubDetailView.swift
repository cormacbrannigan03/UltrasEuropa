import SwiftUI
import UltrasEuropaCore

struct ClubDetailView: View {
    let club: Club

    @Environment(ContentStore.self) private var contentStore

    private var group: UltrasGroup? { contentStore.repository.ultrasGroup(clubId: club.id) }

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
                    Text(club.history).padding(.top, 4)
                }

                if let group {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(group.name).font(.title2.bold())
                        Text("Founded \(String(group.founded))").font(.caption).foregroundStyle(Theme.secondaryText)
                        Text(group.groupDescription)
                        Text("Symbols: \(group.symbols.joined(separator: ", "))").font(.caption)
                        Text("Colors: \(group.colors.joined(separator: ", "))").font(.caption)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
                }

                VStack(spacing: 12) {
                    NavigationLink { ChantsLibraryView(filterClubId: club.id) } label: {
                        ClubLinkRow(title: "Chants", systemImage: "music.mic")
                    }
                    NavigationLink { TifoGalleryView(filterClubId: club.id) } label: {
                        ClubLinkRow(title: "Tifo Gallery", systemImage: "photo.on.rectangle.angled")
                    }
                    NavigationLink { MatchScheduleView(filterClubId: club.id) } label: {
                        ClubLinkRow(title: "Matches", systemImage: "sportscourt.fill")
                    }
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
