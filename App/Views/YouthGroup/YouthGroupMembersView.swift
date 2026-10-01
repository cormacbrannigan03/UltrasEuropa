import SwiftUI
import UltrasEuropaCore

/// Everyone in the player's youth group: the player themselves, every
/// specifically-recruited crew member (see
/// `CharacterStore.recruitToYouthGroup(memberId:)`), and a single rolled-up
/// row for anyone who joined on their own via an unprompted request (see
/// `CharacterStore.resolveYouthGroupJoinRequest`) — those have no identity
/// behind them, just a count.
struct YouthGroupMembersView: View {
    @Environment(CharacterStore.self) private var characterStore

    var body: some View {
        List {
            Section("You") {
                Label(characterStore.character?.name ?? "You", systemImage: "person.fill")
                    .foregroundStyle(Theme.primaryText)
            }
            .listRowBackground(Theme.cardBackground)

            if !characterStore.youthGroupNamedMembers.isEmpty {
                Section("Recruited") {
                    ForEach(characterStore.youthGroupNamedMembers) { member in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(member.name).foregroundStyle(Theme.primaryText)
                            Text(member.rank.displayName).font(.caption).foregroundStyle(Theme.secondaryText)
                        }
                    }
                    .listRowBackground(Theme.cardBackground)
                }
            }

            if characterStore.youthGroupAnonymousMemberCount > 0 {
                Section {
                    Text("+\(characterStore.youthGroupAnonymousMemberCount) more who joined on their own")
                        .foregroundStyle(Theme.secondaryText)
                }
                .listRowBackground(Theme.cardBackground)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Members")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        YouthGroupMembersView()
    }
    .environment(PreviewSampleData.characterStore)
    .preferredColorScheme(.dark)
}
