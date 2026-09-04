import SwiftUI
import UltrasEuropaCore

struct CharacterCreationView: View {
    @Environment(CharacterStore.self) private var characterStore
    @Environment(ContentStore.self) private var contentStore

    @State private var name = ""
    @State private var selectedClubId: String?

    private var trimmedName: String { name.trimmingCharacters(in: .whitespaces) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create Your Fan")
                            .font(.largeTitle.bold())
                        Text("Every Capo started out as a regular fan. Pick a name and a club to follow — the rest you'll earn.")
                            .foregroundStyle(Theme.secondaryText)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name").font(.headline)
                        TextField("Your fan name", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Favorite Club").font(.headline)
                        ForEach(contentStore.repository.clubs) { club in
                            ClubPickerRow(club: club, isSelected: club.id == selectedClubId)
                                .contentShape(Rectangle())
                                .onTapGesture { selectedClubId = club.id }
                        }
                    }

                    Button {
                        guard let selectedClubId else { return }
                        characterStore.createCharacter(name: trimmedName, favoriteClubId: selectedClubId)
                    } label: {
                        Text("Start as a Regular")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }
                    .disabled(trimmedName.isEmpty || selectedClubId == nil)
                }
                .padding()
            }
            .background(Theme.background)
            .scrollContentBackground(.hidden)
        }
    }
}

private struct ClubPickerRow: View {
    let club: Club
    let isSelected: Bool

    var body: some View {
        HStack {
            PlaceholderArt(
                primaryColorHex: club.primaryColorHex,
                secondaryColorHex: club.secondaryColorHex,
                symbolName: "shield.fill"
            )
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading) {
                Text(club.name).font(.subheadline.bold())
                Text("\(club.city), \(club.country)").font(.caption).foregroundStyle(Theme.secondaryText)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.accent)
            }
        }
        .padding(12)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Theme.accent : .clear, lineWidth: 2)
        )
    }
}

#Preview {
    CharacterCreationView()
        .environment(PreviewSampleData.characterStore)
        .environment(PreviewSampleData.contentStore)
        .preferredColorScheme(.dark)
}
