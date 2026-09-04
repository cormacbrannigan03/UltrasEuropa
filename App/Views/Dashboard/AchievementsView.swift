import SwiftUI
import UltrasEuropaCore

struct AchievementsView: View {
    @Environment(CharacterStore.self) private var characterStore
    @Environment(ContentStore.self) private var contentStore

    var body: some View {
        List(contentStore.repository.achievementCatalog) { achievement in
            let unlocked = characterStore.unlockedAchievementIDs.contains(achievement.id)
            HStack {
                Image(systemName: unlocked ? "rosette" : "lock.fill")
                    .foregroundStyle(unlocked ? Theme.accent : Theme.secondaryText)
                VStack(alignment: .leading) {
                    Text(achievement.name).font(.headline)
                    Text(achievement.achievementDescription).font(.caption).foregroundStyle(Theme.secondaryText)
                }
            }
            .opacity(unlocked ? 1 : 0.5)
            .listRowBackground(Theme.cardBackground)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Achievements")
    }
}
