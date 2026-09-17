import SwiftUI
import UltrasEuropaCore

struct WardrobeView: View {
    @Environment(CharacterStore.self) private var characterStore
    @Environment(ContentStore.self) private var contentStore

    @State private var showLaunchSheet = false

    var body: some View {
        List {
            ForEach(ClothingSlot.allCases, id: \.self) { slot in
                Section(slot.displayName) {
                    ForEach(contentStore.repository.clothingItemsInSlot(slot)) { item in
                        WardrobeRow(
                            name: item.name,
                            description: item.clothingDescription,
                            isEquipped: characterStore.equippedItemId(for: slot) == item.id
                        )
                        .contentShape(Rectangle())
                        .onTapGesture { characterStore.equip(itemId: item.id, slot: slot) }
                    }
                    ForEach(characterStore.designedClothingItemsInSlot(slot)) { item in
                        WardrobeRow(
                            name: item.name,
                            description: "Your own design.",
                            isEquipped: characterStore.equippedItemId(for: slot) == item.id
                        )
                        .contentShape(Rectangle())
                        .onTapGesture { characterStore.equip(itemId: item.id, slot: slot) }
                    }
                }
                .listRowBackground(Theme.cardBackground)
            }

            Section("Your Clothing Range") {
                if characterStore.canLaunchClothingRange {
                    Button {
                        showLaunchSheet = true
                    } label: {
                        Label("Launch a Clothing Range", systemImage: "sparkles")
                            .foregroundStyle(Theme.accent)
                    }
                } else {
                    Text("Reach Capo to launch your own clothing range and sell it to your crew.")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            .listRowBackground(Theme.cardBackground)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Wardrobe")
        .sheet(isPresented: $showLaunchSheet) {
            LaunchClothingRangeSheet()
        }
    }
}

private struct WardrobeRow: View {
    let name: String
    let description: String
    let isEquipped: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.subheadline.bold())
                Text(description).font(.caption).foregroundStyle(Theme.secondaryText)
            }
            Spacer()
            if isEquipped {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.accent)
            }
        }
    }
}

private struct LaunchClothingRangeSheet: View {
    @Environment(CharacterStore.self) private var characterStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var slot: ClothingSlot = .top
    @State private var pendingOutcome: ActivityOutcomeSummary?
    @State private var showOutcome = false

    private var trimmedName: String { name.trimmingCharacters(in: .whitespaces) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Range Name") {
                    TextField("e.g. Capo Collection Jacket", text: $name)
                }
                Section("Slot") {
                    Picker("Slot", selection: $slot) {
                        ForEach(ClothingSlot.allCases, id: \.self) { slot in
                            Text(slot.displayName).tag(slot)
                        }
                    }
                }
                Section {
                    Text("Launching sells your range to the crew — everyone's relationship with you gets a boost.")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            .navigationTitle("Launch a Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Launch") {
                        pendingOutcome = characterStore.launchClothingRange(name: trimmedName, slot: slot)
                        showOutcome = true
                    }
                    .disabled(trimmedName.isEmpty)
                }
            }
            .alert("Range Launched", isPresented: $showOutcome, presenting: pendingOutcome) { _ in
                Button("OK") { dismiss() }
            } message: { outcome in
                Text(outcome.displayText)
            }
        }
    }
}
