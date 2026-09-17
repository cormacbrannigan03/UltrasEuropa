import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var contentStore = ContentStore()
    @State private var characterStore: CharacterStore?
    @State private var saveSlotStore: SaveSlotStore?

    var body: some View {
        Group {
            if let characterStore, let saveSlotStore {
                if let activeSlot = saveSlotStore.activeSlotIndex {
                    if characterStore.hasCharacter {
                        RootTabView()
                            .environment(characterStore)
                            .environment(contentStore)
                            .environment(saveSlotStore)
                            .onAppear { characterStore.refreshDailyStreak() }
                    } else {
                        CharacterCreationView(slotIndex: activeSlot)
                            .environment(characterStore)
                            .environment(contentStore)
                    }
                } else {
                    SaveSlotsView()
                        .environment(saveSlotStore)
                        .environment(contentStore)
                }
            } else {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.background)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if characterStore == nil {
                let newCharacterStore = CharacterStore(modelContext: modelContext, content: contentStore.repository)
                let newSaveSlotStore = SaveSlotStore(modelContext: modelContext, content: contentStore.repository)
                if let activeSlot = newSaveSlotStore.activeSlotIndex {
                    newCharacterStore.loadCharacter(inSlot: activeSlot)
                }
                characterStore = newCharacterStore
                saveSlotStore = newSaveSlotStore
            }
        }
        .onChange(of: saveSlotStore?.activeSlotIndex) { _, newSlot in
            guard let characterStore else { return }
            if let newSlot {
                characterStore.loadCharacter(inSlot: newSlot)
            } else {
                characterStore.clearActiveCharacter()
                saveSlotStore?.refreshSlots()
            }
        }
        .onChange(of: characterStore?.hasCharacter) { _, hasCharacter in
            // A brand-new save was just created into the active (previously
            // empty) slot — refresh the picker's summaries so it's accurate
            // the next time "Switch Save" is used.
            if hasCharacter == true {
                saveSlotStore?.refreshSlots()
            }
        }
    }
}
