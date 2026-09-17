import SwiftUI
import UltrasEuropaCore

/// The player's own crew's tifo gallery — generic content, not tied to any
/// specific real club or real ultras group. Only some upcoming matches get
/// a tifo prepared (see `ContentRepository.preparedTifo`), so this isn't a
/// flat list of always-available actions: each display shows whether it's
/// actually planned for one of the favorite club's upcoming games, and
/// contributing to it only happens by attending that match.
struct TifoGalleryView: View {
    @Environment(ContentStore.self) private var contentStore
    @Environment(CharacterStore.self) private var characterStore

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    private var upcomingClubMatches: [Match] {
        guard let favoriteClub = characterStore.favoriteClub else { return [] }
        return characterStore.matchesForClub(favoriteClub.id).filter { !$0.isPlayed }
    }

    private func preparedMatch(for photo: TifoPhoto) -> Match? {
        upcomingClubMatches.first { contentStore.repository.preparedTifo(matchId: $0.id)?.id == photo.id }
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(contentStore.repository.tifoPhotos) { photo in
                    NavigationLink(value: photo) {
                        TifoThumbnail(photo: photo, isPrepared: preparedMatch(for: photo) != nil)
                    }
                }
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("Crew Gallery")
        .navigationDestination(for: TifoPhoto.self) { photo in
            TifoDetailView(photo: photo, preparedMatch: preparedMatch(for: photo))
        }
    }
}

private struct TifoThumbnail: View {
    let photo: TifoPhoto
    let isPrepared: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            PlaceholderArt(
                primaryColorHex: Theme.crewPrimaryHex,
                secondaryColorHex: Theme.crewSecondaryHex,
                symbolName: "flame.fill",
                caption: photo.caption
            )
            .aspectRatio(1, contentMode: .fill)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .opacity(isPrepared ? 1 : 0.55)

            if isPrepared {
                Text("Planned")
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.accent, in: Capsule())
                    .foregroundStyle(.white)
                    .padding(6)
            }
        }
    }
}

struct TifoDetailView: View {
    let photo: TifoPhoto
    let preparedMatch: Match?

    @Environment(ContentStore.self) private var contentStore

    private var homeClubName: String? {
        preparedMatch.flatMap { contentStore.repository.club(id: $0.homeClubId)?.name }
    }

    private var awayClubName: String? {
        preparedMatch.flatMap { contentStore.repository.club(id: $0.awayClubId)?.name }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PlaceholderArt(
                    primaryColorHex: Theme.crewPrimaryHex,
                    secondaryColorHex: Theme.crewSecondaryHex,
                    symbolName: "flame.fill",
                    caption: photo.caption
                )
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Text(photo.caption).font(.body)

                if let preparedMatch, let homeClubName, let awayClubName {
                    NavigationLink(value: preparedMatch) {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Planned for an Upcoming Match", systemImage: "calendar")
                                .font(.headline)
                                .foregroundStyle(Theme.accent)
                            Text("\(homeClubName) vs \(awayClubName)")
                                .font(.subheadline.bold())
                            Text(preparedMatch.date, style: .date)
                                .font(.caption)
                                .foregroundStyle(Theme.secondaryText)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
                    }
                } else {
                    Text("Not currently planned for any of your club's upcoming matches — check back as the season progresses.")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("Tifo")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Match.self) { match in
            MatchDetailView(match: match)
        }
    }
}
