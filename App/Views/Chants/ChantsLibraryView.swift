import SwiftUI
import UltrasEuropaCore

/// The player's own crew's chant book — generic content, not tied to any
/// specific real club or real ultras group.
struct ChantsLibraryView: View {
    @Environment(ContentStore.self) private var contentStore
    @State private var searchText = ""

    private var filteredChants: [Chant] {
        let all = contentStore.repository.chants
        guard !searchText.isEmpty else { return all }
        return all.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List(filteredChants) { chant in
            NavigationLink(value: chant) {
                Text(chant.title)
            }
            .listRowBackground(Theme.cardBackground)
        }
        .searchable(text: $searchText)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Crew Chants")
        .navigationDestination(for: Chant.self) { chant in
            ChantDetailView(chant: chant)
        }
    }
}
