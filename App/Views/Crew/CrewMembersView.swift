import SwiftUI
import UltrasEuropaCore

/// The player's crew roster, grouped by rank (most senior first) — visible
/// once a character exists, since it's this character's own crew.
struct CrewMembersView: View {
    @Environment(ContentStore.self) private var contentStore
    @Environment(CharacterStore.self) private var characterStore

    private var ranksMostSeniorFirst: [Rank] {
        Array(Rank.allCases.reversed())
    }

    var body: some View {
        List {
            ForEach(ranksMostSeniorFirst, id: \.self) { rank in
                let members = contentStore.repository.crewMembersInRank(rank)
                if !members.isEmpty {
                    Section(rank.displayName) {
                        ForEach(members) { member in
                            NavigationLink(value: member) {
                                CrewMemberRow(member: member, bondScore: characterStore.bondScore(forMember: member.id))
                            }
                        }
                        .listRowBackground(Theme.cardBackground)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Crew Members")
        .navigationDestination(for: CrewMember.self) { member in
            CrewMemberDetailView(member: member)
        }
    }
}

private struct CrewMemberRow: View {
    let member: CrewMember
    let bondScore: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(member.name).font(.headline)
                Text(member.personality).font(.caption).foregroundStyle(Theme.secondaryText)
            }
            Spacer()
            Text(RelationshipLevel.level(forBond: bondScore).displayName)
                .font(.caption.bold())
                .foregroundStyle(Theme.accent)
        }
    }
}
