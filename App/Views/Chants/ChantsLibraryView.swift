import SwiftUI
import UltrasEuropaCore

struct ChantsLibraryView: View {
    var filterClubId: String? = nil

    @Environment(ContentStore.self) private var contentStore
    @State private var searchText = ""

    private var filteredChants: [Chant] {
        var list = contentStore.repository.chants
        if let filterClubId { list = list.filter { $0.clubId == filterClubId } }
        if !searchText.isEmpty {
            list = list.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        return list
    }

    private var groupedByClub: [(club: Club?, chants: [Chant])] {
        let grouped = Dictionary(grouping: filteredChants, by: \.clubId)
        let pairs: [(club: Club?, chants: [Chant])] = grouped.map { key, value in
            (club: contentStore.repository.club(id: key), chants: value)
        }
        return pairs.sorted { ($0.club?.name ?? "") < ($1.club?.name ?? "") }
    }

    var body: some View {
        List {
            ForEach(groupedByClub, id: \.club?.id) { group in
                Section(group.club?.name ?? "Unknown Club") {
                    ForEach(group.chants) { chant in
                        NavigationLink(value: chant) {
                            Text(chant.title)
                        }
                        .listRowBackground(Theme.cardBackground)
                    }
                }
            }
        }
        .searchable(text: $searchText)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Chants")
        .navigationDestination(for: Chant.self) { chant in
            ChantDetailView(chant: chant)
        }
    }
}
