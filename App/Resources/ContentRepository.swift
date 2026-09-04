import Foundation
import UltrasEuropaCore

/// All bundled, static reference content — clubs, groups, matches, chants,
/// tifo photos, and the inventory/achievement/task catalogs. Loaded once
/// from the app bundle's JSON files (see `App/Resources/Content/`) and
/// treated as read-only for the lifetime of the app.
struct ContentRepository {
    let clubs: [Club]
    let ultrasGroups: [UltrasGroup]
    let matches: [Match]
    let chants: [Chant]
    let tifoPhotos: [TifoPhoto]
    let inventoryCatalog: [InventoryItem]
    let achievementCatalog: [Achievement]
    let tasks: [ChallengeTask]

    static func loadFromBundle(_ bundle: Bundle = .main) -> ContentRepository {
        ContentRepository(
            clubs: load([Club].self, "clubs", bundle: bundle),
            ultrasGroups: load([UltrasGroup].self, "ultras_groups", bundle: bundle),
            matches: load([Match].self, "matches", bundle: bundle),
            chants: load([Chant].self, "chants", bundle: bundle),
            tifoPhotos: load([TifoPhoto].self, "tifo_photos", bundle: bundle),
            inventoryCatalog: load([InventoryItem].self, "inventory_catalog", bundle: bundle),
            achievementCatalog: load([Achievement].self, "achievements_catalog", bundle: bundle),
            tasks: load([ChallengeTask].self, "tasks", bundle: bundle)
        )
    }

    private static func load<T: Decodable>(_ type: T.Type, _ filename: String, bundle: Bundle) -> T {
        // Try a "Content" subdirectory first (folder reference), then the
        // bundle root (plain group membership) — XcodeGen/Xcode can lay the
        // bundled files out either way depending on how the folder is added.
        let url = bundle.url(forResource: filename, withExtension: "json", subdirectory: "Content")
            ?? bundle.url(forResource: filename, withExtension: "json")

        guard let url else {
            fatalError("Missing bundled content file: \(filename).json")
        }

        do {
            let data = try Data(contentsOf: url)
            return try ContentDecoding.decode(T.self, from: data)
        } catch {
            fatalError("Failed to decode \(filename).json: \(error)")
        }
    }

    // MARK: - Lookups

    func club(id: String) -> Club? {
        clubs.first { $0.id == id }
    }

    func ultrasGroup(clubId: String) -> UltrasGroup? {
        ultrasGroups.first { $0.clubId == clubId }
    }

    func inventoryItem(id: String) -> InventoryItem? {
        inventoryCatalog.first { $0.id == id }
    }

    func achievement(id: String) -> Achievement? {
        achievementCatalog.first { $0.id == id }
    }

    func task(id: String) -> ChallengeTask? {
        tasks.first { $0.id == id }
    }
}
