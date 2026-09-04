import SwiftUI
import UltrasEuropaCore

struct CrewMemberDetailView: View {
    let member: CrewMember

    @Environment(CharacterStore.self) private var characterStore
    @State private var pendingResult: CrewInteractionResult?
    @State private var showOutcome = false

    private var bondScore: Int { characterStore.bondScore(forMember: member.id) }
    private var relationshipLevel: RelationshipLevel { RelationshipLevel.level(forBond: bondScore) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(member.name).font(.title.bold())
                    Text(member.personality).font(.subheadline.bold()).foregroundStyle(Theme.accent)
                    Text(member.bio).foregroundStyle(Theme.secondaryText)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Relationship").font(.headline)
                        Spacer()
                        Text(relationshipLevel.displayName).font(.headline).foregroundStyle(Theme.accent)
                    }
                    ProgressView(value: Double(bondScore + 100), total: 200)
                        .tint(Theme.accent)
                }
                .padding(16)
                .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Interact").font(.headline)
                    ForEach(CrewInteractionType.allCases, id: \.self) { type in
                        Button {
                            pendingResult = characterStore.interact(with: member, type: type)
                            showOutcome = pendingResult != nil
                        } label: {
                            Text(type.displayName)
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(Theme.primaryText)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle(member.name)
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            pendingResult?.outcome.didGoWell == true ? "Went Well" : "Didn't Go Well",
            isPresented: $showOutcome, presenting: pendingResult
        ) { _ in
            Button("OK") { pendingResult = nil }
        } message: { result in
            Text(resultMessage(result))
        }
    }

    private func resultMessage(_ result: CrewInteractionResult) -> String {
        var lines = [result.outcome.message]
        lines.append("Relationship \(result.outcome.bondDelta >= 0 ? "+" : "")\(result.outcome.bondDelta)")
        if let xpOutcome = result.xpOutcome {
            lines.append(xpOutcome.displayText)
        }
        return lines.joined(separator: "\n")
    }
}
