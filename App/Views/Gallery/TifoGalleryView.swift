import SwiftUI
import UltrasEuropaCore

/// The player's own crew's tifo gallery — generic content, not tied to any
/// specific real club, match, or real ultras group.
struct TifoGalleryView: View {
    @Environment(ContentStore.self) private var contentStore

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(contentStore.repository.tifoPhotos) { photo in
                    NavigationLink(value: photo) {
                        TifoThumbnail(photo: photo)
                    }
                }
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("Crew Gallery")
        .navigationDestination(for: TifoPhoto.self) { photo in
            TifoDetailView(photo: photo)
        }
    }
}

private struct TifoThumbnail: View {
    let photo: TifoPhoto

    var body: some View {
        PlaceholderArt(
            primaryColorHex: Theme.crewPrimaryHex,
            secondaryColorHex: Theme.crewSecondaryHex,
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
    @State private var showOutcome = false

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
