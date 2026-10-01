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
            DesignedClothingItemEntity.self,
            AwayTicketAttemptEntity.self,
            HomeSeatRequestEntity.self,
            UltraViolenceIncidentEntity.self,
            ClubFriendshipEntity.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // A schema change between TestFlight/App Store builds (an
            // added or removed field) can leave an on-device store that
            // SwiftData's automatic lightweight migration can't open,
            // which previously crashed the app on every single launch
            // from then on with no way for the player to recover short of
            // deleting the app. With no backend or sync, losing that
            // local save once is a far better outcome than a permanently
            // unlaunchable app, so fall back to resetting the store and
            // starting fresh.
            resetExistingStore(at: configuration.url)
            do {
                return try ModelContainer(for: schema, configurations: [configuration])
            } catch {
                fatalError("Failed to create ModelContainer even after resetting the store: \(error)")
            }
        }
    }

    /// Deletes the SQLite store file backing `url`, plus its `-wal`/`-shm`
    /// sidecar files, so a fresh `ModelContainer(for:configurations:)`
    /// call can create an empty store in its place.
    private static func resetExistingStore(at url: URL) {
        let fileManager = FileManager.default
        for suffix in ["", "-wal", "-shm"] {
            let fileURL = URL(fileURLWithPath: url.path + suffix)
            try? fileManager.removeItem(at: fileURL)
        }
    }
}
