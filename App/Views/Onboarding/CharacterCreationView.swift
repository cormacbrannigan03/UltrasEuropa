import SwiftUI
import UltrasEuropaCore

struct CharacterCreationView: View {
    @Environment(CharacterStore.self) private var characterStore
    @Environment(ContentStore.self) private var contentStore

    @State private var name = ""
    @State private var crewName = ""
    @State private var selectedClubId: String?
    @State private var showClubPicker = false

    private var trimmedName: String { name.trimmingCharacters(in: .whitespaces) }
    private var trimmedCrewName: String { crewName.trimmingCharacters(in: .whitespaces) }
    private var selectedClub: Club? {
        selectedClubId.flatMap { contentStore.repository.club(id: $0) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create Your Fan")
                            .font(.largeTitle.bold())
                        Text("Every Capo started out as a regular fan. Pick a name, form your own crew, and choose a club to follow — the rest you'll earn.")
                            .foregroundStyle(Theme.secondaryText)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name").font(.headline)
                        TextField("Your fan name", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Crew Name").font(.headline)
                        Text("The chants and tifo you earn belong to your own crew, not a real ultras group.")
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryText)
                        TextField("e.g. The North Bank Firm", text: $crewName)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Favorite Club").font(.headline)
                        Button {
                            showClubPicker = true
                        } label: {
                            if let selectedClub {
                                ClubPickerRow(club: selectedClub, isSelected: true)
                            } else {
                                Text("Choose a club")
                                    .font(.subheadline.bold())
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                                    .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                                    .foregroundStyle(Theme.primaryText)
                            }
                        }
                    }

                    Button {
                        guard let selectedClubId else { return }
                        characterStore.createCharacter(
                            name: trimmedName, favoriteClubId: selectedClubId, crewName: trimmedCrewName
                        )
                    } label: {
                        Text("Start as a Regular")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }
                    .disabled(trimmedName.isEmpty || trimmedCrewName.isEmpty || selectedClubId == nil)
                }
                .padding()
            }
            .background(Theme.background)
            .scrollContentBackground(.hidden)
            .sheet(isPresented: $showClubPicker) {
                ClubPickerSheet(selectedClubId: $selectedClubId)
            }
        }
    }
}

private struct ClubPickerSheet: View {
    @Binding var selectedClubId: String?
    @Environment(ContentStore.self) private var contentStore
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var leaguesWithClubs: [(league: League, clubs: [Club])] {
        let leagues = contentStore.repository.leagues.sorted { $0.rank < $1.rank }
        var result: [(league: League, clubs: [Club])] = []
        for league in leagues {
            var clubs = contentStore.repository.clubsInLeague(league.id)
            if !searchText.isEmpty {
                clubs = clubs.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
            }
            if !clubs.isEmpty {
                result.append((league: league, clubs: clubs))
            }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(leaguesWithClubs, id: \.league.id) { entry in
                    Section("\(entry.league.name) — \(entry.league.country)") {
                        ForEach(entry.clubs) { club in
                            Button {
                                selectedClubId = club.id
                                dismiss()
                            } label: {
                                ClubPickerRow(club: club, isSelected: club.id == selectedClubId)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listRowBackground(Theme.cardBackground)
                }
            }
            .searchable(text: $searchText, prompt: "Search clubs")
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Choose a Club")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
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
