import Foundation
import SwiftData
import Observation
import UltrasEuropaCore

/// One row in the save-slot picker — a fixed slot index (`0..<SaveSlotStore.maxSlots`)
/// that either holds a character (a completed save) or is empty and ready
/// for a new one.
struct SaveSlotSummary: Identifiable {
    let slotIndex: Int
    let name: String?
    let clubName: String?
    let rank: Rank?
    let lastActiveDate: Date?

    var id: Int { slotIndex }
    var isEmpty: Bool { name == nil }
}

/// Owns which of up to three save slots is currently active, and the
/// summaries shown on the save-slot picker. `CharacterStore` owns
/// everything about the character *within* the active slot (stats, rank,
/// every earning action) — this type only knows which slot that is and
/// what the other slots contain, so the two can't fight over ownership of
/// the same state.
///
/// The active slot is remembered in `UserDefaults` (not SwiftData — it's a
/// per-device UI preference, not game data) so relaunching the app resumes
/// straight into the same save without showing the picker again.
@Observable
final class SaveSlotStore {
    /// Hard cap on concurrent saves. A fixed, small number keeps the picker
    /// a simple 3-row screen rather than an open-ended list to manage.
    static let maxSlots = 3

    private let modelContext: ModelContext
    private let content: ContentRepository
    private static let activeSlotDefaultsKey = "UltrasEuropa.activeSaveSlotIndex"

    private(set) var slotSummaries: [SaveSlotSummary] = []
    private(set) var activeSlotIndex: Int?

    init(modelContext: ModelContext, content: ContentRepository) {
        self.modelContext = modelContext
        self.content = content
        refreshSlots()

        if let rememberedSlot = UserDefaults.standard.object(forKey: Self.activeSlotDefaultsKey) as? Int,
           let summary = slotSummaries.first(where: { $0.slotIndex == rememberedSlot }),
           !summary.isEmpty {
            activeSlotIndex = rememberedSlot
        }
    }

    /// Re-reads all saved characters and rebuilds the fixed-size slot list.
    /// Call after creating or deleting a save.
    func refreshSlots() {
        let characters = (try? modelContext.fetch(FetchDescriptor<CharacterEntity>())) ?? []
        slotSummaries = (0..<Self.maxSlots).map { slot in
            guard let character = characters.first(where: { $0.slotIndex == slot }) else {
                return SaveSlotSummary(slotIndex: slot, name: nil, clubName: nil, rank: nil, lastActiveDate: nil)
            }
            return SaveSlotSummary(
                slotIndex: slot,
                name: character.name,
                clubName: content.club(id: character.favoriteClubId)?.name,
                rank: PersistenceMapper.rank(from: character),
                lastActiveDate: character.lastActiveDate
            )
        }
    }

    /// Makes `slotIndex` the active slot and remembers it for next launch.
    /// Doesn't itself load or create a character — `RootView` reacts to the
    /// change and asks `CharacterStore` to load the existing one, or shows
    /// character creation if the slot was empty.
    func selectSlot(_ slotIndex: Int) {
        activeSlotIndex = slotIndex
        UserDefaults.standard.set(slotIndex, forKey: Self.activeSlotDefaultsKey)
    }

    /// Returns to the save-slot picker without deleting anything — used by
    /// the in-game "Switch Save" action.
    func clearActiveSlot() {
        activeSlotIndex = nil
        UserDefaults.standard.removeObject(forKey: Self.activeSlotDefaultsKey)
    }

    /// Permanently deletes the save in `slotIndex` (cascades to every
    /// relationship on that character, same as any other character
    /// deletion) and frees the slot for a new save.
    func deleteSave(inSlot slotIndex: Int) {
        let characters = (try? modelContext.fetch(FetchDescriptor<CharacterEntity>())) ?? []
        if let character = characters.first(where: { $0.slotIndex == slotIndex }) {
            modelContext.delete(character)
            try? modelContext.save()
        }
        refreshSlots()
        if activeSlotIndex == slotIndex {
            clearActiveSlot()
        }
    }
}
