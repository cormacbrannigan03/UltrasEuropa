import SwiftUI
import UltrasEuropaCore

/// Shown whenever there's no active save (first launch, or after tapping
/// "Switch Save" from the Dashboard) — lets the player continue an
/// existing fan, start a new one in an empty slot, or delete a save to
/// free it up. Always exactly `SaveSlotStore.maxSlots` rows.
struct SaveSlotsView: View {
    @Environment(SaveSlotStore.self) private var saveSlotStore

    @State private var slotPendingDeletion: Int?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Saves")
                            .font(.largeTitle.bold())
                        Text("Up to \(SaveSlotStore.maxSlots) fans, each with their own crew, club, and climb.")
                            .foregroundStyle(Theme.secondaryText)
                    }

                    VStack(spacing: 12) {
                        ForEach(saveSlotStore.slotSummaries) { summary in
                            SaveSlotRow(
                                summary: summary,
                                onSelect: { saveSlotStore.selectSlot(summary.slotIndex) },
                                onDelete: { slotPendingDeletion = summary.slotIndex }
                            )
                        }
                    }
                }
                .padding()
            }
            .background(Theme.background)
            .navigationTitle("UltrasEuropa")
            .navigationBarTitleDisplayMode(.inline)
            .alert(
                "Delete This Save?",
                isPresented: Binding(
                    get: { slotPendingDeletion != nil },
                    set: { isPresented in if !isPresented { slotPendingDeletion = nil } }
                )
            ) {
                Button("Delete", role: .destructive) {
                    if let slot = slotPendingDeletion {
                        saveSlotStore.deleteSave(inSlot: slot)
                    }
                    slotPendingDeletion = nil
                }
                Button("Cancel", role: .cancel) { slotPendingDeletion = nil }
            } message: {
                Text("This permanently deletes this fan's rank, stats, and everything they've earned. This can't be undone.")
            }
        }
    }
}

private struct SaveSlotRow: View {
    let summary: SaveSlotSummary
    let onSelect: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onSelect) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        if summary.isEmpty {
                            Text("New Save").font(.headline)
                            Text("Create a new fan").font(.caption).foregroundStyle(Theme.secondaryText)
                        } else {
                            Text(summary.name ?? "").font(.headline)
                            if let clubName = summary.clubName {
                                Text("Follows \(clubName)").font(.caption).foregroundStyle(Theme.secondaryText)
                            }
                            if let rank = summary.rank {
                                RankBadge(rank: rank)
                            }
                        }
                    }
                    Spacer()
                    Image(systemName: summary.isEmpty ? "plus.circle.fill" : "chevron.right")
                        .foregroundStyle(summary.isEmpty ? Theme.accent : Theme.secondaryText)
                }
            }
            .buttonStyle(.plain)

            if !summary.isEmpty {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
        .foregroundStyle(Theme.primaryText)
    }
}
