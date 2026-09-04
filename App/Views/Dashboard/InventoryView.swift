import SwiftUI
import UltrasEuropaCore

struct InventoryView: View {
    @Environment(CharacterStore.self) private var characterStore
    @Environment(ContentStore.self) private var contentStore

    var body: some View {
        List(contentStore.repository.inventoryCatalog) { item in
            let owned = characterStore.ownedItemIDs.contains(item.id)
            HStack {
                Image(systemName: owned ? "checkmark.seal.fill" : "lock.fill")
                    .foregroundStyle(owned ? Theme.accent : Theme.secondaryText)
                VStack(alignment: .leading) {
                    Text(item.name).font(.headline)
                    Text(item.itemDescription).font(.caption).foregroundStyle(Theme.secondaryText)
                }
            }
            .opacity(owned ? 1 : 0.5)
            .listRowBackground(Theme.cardBackground)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Inventory")
    }
}
