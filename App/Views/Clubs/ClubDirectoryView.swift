import SwiftUI
import UltrasEuropaCore

struct ClubDirectoryView: View {
    @Environment(ContentStore.self) private var contentStore

    var body: some View {
        List(contentStore.repository.clubs) { club in
            NavigationLink(value: club) {
                HStack {
                    PlaceholderArt(
                        primaryColorHex: club.primaryColorHex,
                        secondaryColorHex: club.secondaryColorHex,
                        symbolName: "shield.fill"
                    )
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading) {
                        Text(club.name).font(.headline)
                        Text("\(club.city), \(club.country)").font(.caption).foregroundStyle(Theme.secondaryText)
                    }
                }
            }
            .listRowBackground(Theme.cardBackground)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Clubs")
        .navigationDestination(for: Club.self) { club in
            ClubDetailView(club: club)
        }
    }
}
