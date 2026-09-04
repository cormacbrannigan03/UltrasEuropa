import Foundation
import SwiftData
import UltrasEuropaCore

/// In-memory sample data for SwiftUI `#Preview` blocks only — never used by
/// the running app (see `ModelContainerFactory` for the real, on-disk
/// container).
@MainActor
enum PreviewSampleData {
    static let content = ContentRepository.loadFromBundle()

    static var modelContainer: ModelContainer = {
        let schema = Schema([
            CharacterEntity.self,
            OwnedItemEntity.self,
            UnlockedAchievementEntity.self,
            MatchAttendanceEntity.self,
            ActivityLogEntity.self,
            CompletedTaskEntity.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        guard let container = try? ModelContainer(for: schema, configurations: [configuration]) else {
            fatalError("Failed to create in-memory preview ModelContainer")
        }

        let character = CharacterEntity(name: "Marco", favoriteClubId: content.clubs.first?.id ?? "rotstadt")
        character.totalXP = 120
        character.loyalty = 20
        character.knowledge = 10
        character.influence = 8
        character.notoriety = 4
        character.matchesAttended = 3
        character.currentStreakDays = 5
        container.mainContext.insert(character)

        return container
    }()

    static var characterStore: CharacterStore {
        CharacterStore(modelContext: modelContainer.mainContext, content: content)
    }

    static var contentStore: ContentStore {
        ContentStore(repository: content)
    }
}
