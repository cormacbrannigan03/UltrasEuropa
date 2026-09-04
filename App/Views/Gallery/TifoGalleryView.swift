import SwiftUI
import UltrasEuropaCore

struct TifoGalleryView: View {
    var filterClubId: String? = nil

    @Environment(ContentStore.self) private var contentStore

    private var photos: [TifoPhoto] {
        let all = contentStore.repository.tifoPhotos
        guard let filterClubId else { return all }
        return all.filter { $0.clubId == filterClubId }
    }

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(photos) { photo in
                    NavigationLink(value: photo) {
                        TifoThumbnail(photo: photo)
                    }
                }
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("Gallery")
        .navigationDestination(for: TifoPhoto.self) { photo in
            TifoDetailView(photo: photo)
        }
    }
}

private struct TifoThumbnail: View {
    let photo: TifoPhoto
    @Environment(ContentStore.self) private var contentStore

    private var club: Club? { contentStore.repository.club(id: photo.clubId) }

    var body: some View {
        PlaceholderArt(
            primaryColorHex: club?.primaryColorHex ?? "#444444",
            secondaryColorHex: club?.secondaryColorHex ?? "#888888",
            symbolName: "flame.fill",
            caption: photo.caption
        )
        .aspectRatio(1, contentMode: .fill)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct TifoDetailView: View {
    let photo: TifoPhoto

    @Environment(CharacterStore.self) private var characterStore
    @Environment(ContentStore.self) private var contentStore
    @State private var showOutcome = false

    private var club: Club? { contentStore.repository.club(id: photo.clubId) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PlaceholderArt(
                    primaryColorHex: club?.primaryColorHex ?? "#444444",
                    secondaryColorHex: club?.secondaryColorHex ?? "#888888",
                    symbolName: "flame.fill",
                    caption: photo.caption
                )
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Text(photo.caption).font(.body)
                if let club { Text(club.name).foregroundStyle(Theme.secondaryText) }

                Button {
                    characterStore.recordActivity(.contributeToTifo)
                    showOutcome = true
                } label: {
                    Text("Contribute to This Tifo")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                }
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("Tifo")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Tifo", isPresented: $showOutcome, presenting: characterStore.lastOutcome) { _ in
            Button("OK") { characterStore.lastOutcome = nil }
        } message: { outcome in
            Text(outcome.displayText)
        }
    }
}
