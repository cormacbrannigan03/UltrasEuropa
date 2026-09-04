import Foundation
import SwiftData

enum ModelContainerFactory {
    /// A single, fully-local (no CloudKit) container — this app has no
    /// backend and no sync.
    static func make() -> ModelContainer {
        let schema = Schema([
            CharacterEntity.self,
            OwnedItemEntity.self,
            UnlockedAchievementEntity.self,
            MatchAttendanceEntity.self,
            ActivityLogEntity.self,
            CompletedTaskEntity.self,
            CrewRelationshipEntity.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
