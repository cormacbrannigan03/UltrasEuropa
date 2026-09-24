import SwiftUI
import UltrasEuropaCore

/// Founding and growing the player's own breakaway youth group — a slow,
/// deliberately difficult alternative to the favorite club's main ultras
/// group, which reacts to its growth with everything from indifference to
/// open hostility (see `YouthGroupStage.mainUltrasReaction`). Reaching
/// `YouthGroupEngine.takeoverThreshold` members unlocks a one-time,
/// mutually-exclusive choice: merge peacefully, or take the main group
/// over outright.
struct YouthGroupView: View {
    @Environment(CharacterStore.self) private var characterStore

    @State private var lastRecruitSucceeded: Bool?
    @State private var showRecruitResult = false
    @State private var showMergeConfirmation = false
    @State private var showTakeoverConfirmation = false

    private var stage: YouthGroupStage { characterStore.youthGroupStage }
    private var outcome: YouthGroupOutcome { characterStore.youthGroupOutcome }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if !characterStore.youthGroupFounded {
                    foundingCard
                } else if outcome != .none {
                    outcomeCard
                } else {
                    statusCard
                    sectionCard
                    if characterStore.youthGroupHasPendingJoinRequest {
                        joinRequestCard
                    }
                    mainUltrasReactionCard
                    if characterStore.youthGroupReadyForTakeoverChoice {
                        takeoverChoiceCard
                    } else {
                        recruitCard
                    }
                }
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("Youth Group")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            lastRecruitSucceeded == true ? "They're In!" : "No Luck",
            isPresented: $showRecruitResult
        ) {
            Button("OK") {}
        } message: {
            Text(
                lastRecruitSucceeded == true
                    ? "You've talked someone new into joining your group."
                    : "They weren't interested this time. The bigger your group gets, the harder this becomes — keep at it."
            )
        }
        .confirmationDialog(
            "Merge with the main ultras group?",
            isPresented: $showMergeConfirmation,
            titleVisibility: .visible
        ) {
            Button("Merge") { characterStore.mergeYouthGroupWithMainUltras() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your group folds into the main ultras group for good. This can't be undone.")
        }
        .confirmationDialog(
            "Take over the main ultras group?",
            isPresented: $showTakeoverConfirmation,
            titleVisibility: .visible
        ) {
            Button("Take Over", role: .destructive) { characterStore.takeOverMainUltrasGroup() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your group forces its way to the top, replacing the main group's leadership outright. This can't be undone.")
        }
    }

    private var foundingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Start Your Own Group").font(.headline)
            Text(
                "Break away from the crowd and start bringing people together under your own banner. It starts small — just you — and growing it will be slow. The main ultras group won't be thrilled either."
            )
            .font(.subheadline)
            .foregroundStyle(Theme.secondaryText)

            Button {
                characterStore.foundYouthGroup()
            } label: {
                Text("Found Your Own Group")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(Theme.accentForeground)
            }
        }
        .padding(16)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Stage").font(.headline)
                Spacer()
                Text(stage.displayName).font(.headline).foregroundStyle(Theme.accent)
            }
            Text("\(characterStore.youthGroupMemberCount) member\(characterStore.youthGroupMemberCount == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
            ProgressView(
                value: Double(characterStore.youthGroupMemberCount),
                total: Double(YouthGroupEngine.takeoverThreshold)
            )
            .tint(Theme.accent)
            Text("\(characterStore.youthGroupMemberCount)/\(YouthGroupEngine.takeoverThreshold) members to rival the main ultras group outright")
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
        }
        .padding(16)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    private var sectionBinding: Binding<SeatCategory> {
        Binding(
            get: { characterStore.youthGroupSection },
            set: { characterStore.setYouthGroupSection($0) }
        )
    }

    private var sectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Where You Sit").font(.headline)
            Text("Pick which part of the ground your group bases itself in.")
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
            Picker("Section", selection: sectionBinding) {
                ForEach(SeatCategory.allCases, id: \.self) { section in
                    Text(section.displayName).tag(section)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(16)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    private var joinRequestCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Someone Wants In", systemImage: "person.crop.circle.badge.questionmark")
                .font(.headline)
                .foregroundStyle(Theme.accent)
            Text("Word about your group has spread — a young supporter wants to join, no convincing needed.")
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
            HStack(spacing: 12) {
                Button {
                    characterStore.resolveYouthGroupJoinRequest(accept: true)
                } label: {
                    Text("Let Them In")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(Theme.accentForeground)
                }
                Button {
                    characterStore.resolveYouthGroupJoinRequest(accept: false)
                } label: {
                    Text("Turn Them Away")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
        }
        .padding(16)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    private var mainUltrasReactionCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("The Main Ultras Group", systemImage: "exclamationmark.bubble.fill")
                .font(.subheadline.bold())
                .foregroundStyle(Theme.secondaryText)
            Text(stage.mainUltrasReaction)
                .font(.subheadline)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    private var recruitCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recruit a Member").font(.headline)
            Text("Chance of success: \(Int((characterStore.youthGroupRecruitChance * 100).rounded()))%")
                .font(.subheadline.bold())
                .foregroundStyle(Theme.accent)
            Text("This is meant to be hard — most attempts won't land, and it only gets harder as the group grows.")
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)

            Button {
                lastRecruitSucceeded = characterStore.recruitToYouthGroup()
                showRecruitResult = true
            } label: {
                Text("Try to Recruit Someone")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(Theme.accentForeground)
            }
        }
        .padding(16)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    private var takeoverChoiceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("A Choice Has to Be Made").font(.headline)
            Text(
                "Your group is now large enough to rival the main ultras outright. You can fold it peacefully into the main group, or push to take the main group's place entirely."
            )
            .font(.subheadline)
            .foregroundStyle(Theme.secondaryText)

            Button {
                showMergeConfirmation = true
            } label: {
                Text("Merge With the Main Ultras")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(Theme.accentForeground)
            }

            Button {
                showTakeoverConfirmation = true
            } label: {
                Text("Take Over the Main Ultras Group")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.red, lineWidth: 1.5))
                    .foregroundStyle(.red)
            }
        }
        .padding(16)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    private var outcomeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch outcome {
            case .merged:
                Label("Merged", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundStyle(Theme.accent)
                Text("Your group folded into the main ultras group. What you built together now stands as one.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
            case .tookOver:
                Label("Took Over", systemImage: "crown.fill")
                    .font(.headline)
                    .foregroundStyle(Theme.accent)
                Text("Your group forced its way to the top. The main ultras group now answers to you.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
            case .none:
                EmptyView()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    NavigationStack {
        YouthGroupView()
    }
    .environment(PreviewSampleData.characterStore)
    .preferredColorScheme(.dark)
}
