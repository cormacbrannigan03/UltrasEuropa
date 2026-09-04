import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var contentStore = ContentStore()
    @State private var characterStore: CharacterStore?

    var body: some View {
        Group {
            if let characterStore {
                if characterStore.hasCharacter {
                    RootTabView()
                        .environment(characterStore)
                        .environment(contentStore)
                        .onAppear { characterStore.refreshDailyStreak() }
                } else {
                    CharacterCreationView()
                        .environment(characterStore)
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
                characterStore = CharacterStore(modelContext: modelContext, content: contentStore.repository)
            }
        }
    }
}
