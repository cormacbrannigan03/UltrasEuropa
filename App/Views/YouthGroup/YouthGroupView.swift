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
    @Environment(ContentStore.self) private var contentStore

    @State private var lastRecruitSucceeded: Bool?
    @State private var lastRecruitedMemberName = ""
    @State private var showRecruitResult = false
    @State private var showRecruitSheet = false
    @State private var showMergeConfirmation = false
    @State private var showTakeoverConfirmation = false
    @State private var newGroupName = ""

    private var stage: YouthGroupStage { characterStore.youthGroupStage }
    private var outcome: YouthGroupOutcome { characterStore.youthGroupOutcome }

    /// Clubs your own crew's ultras group has an accepted friendship
    /// with (see `ClubDetailView`'s friendship proposal) — shown here
    /// too since it's part of the same "who's backing you up" picture as
    /// the youth group itself.
    private var friendClubs: [Club] {
        characterStore.friendClubIds
            .compactMap { contentStore.repository.club(id: $0) }
            .sorted { $0.name < $1.name }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if !characterStore.youthGroupFounded {
                    foundingCard
                } else if outcome != .none {
                    outcomeCard
                } else {
                    statusCard
                    if !friendClubs.isEmpty {
                        friendshipsCard
                    }
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
        .navigationTitle(characterStore.youthGroupFounded ? characterStore.youthGroupName : "Youth Group")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            lastRecruitSucceeded == true ? "They're In!" : "No Luck",
            isPresented: $showRecruitResult
        ) {
            Button("OK") {}
        } message: {
            Text(
                lastRecruitSucceeded == true
                    ? "\(lastRecruitedMemberName) is in — welcome to the group."
                    : "\(lastRecruitedMemberName) wasn't interested this time. The bigger your group gets, the harder this becomes — keep at it."
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

            VStack(alignment: .leading, spacing: 4) {
                Text("Group Name").font(.caption.bold()).foregroundStyle(Theme.secondaryText)
                TextField("e.g. The Young Guns", text: $newGroupName)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
            }

            Button {
                characterStore.foundYouthGroup(name: newGroupName)
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
            Text(characterStore.youthGroupName).font(.title3.bold()).foregroundStyle(Theme.primaryText)
            HStack {
                Text("Stage").font(.headline)
                Spacer()
                Text(stage.displayName).font(.headline).foregroundStyle(Theme.accent)
            }
            NavigationLink {
                YouthGroupMembersView()
            } label: {
                HStack {
                    Text("\(characterStore.youthGroupMemberCount) member\(characterStore.youthGroupMemberCount == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundStyle(Theme.accent)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            ProgressView(
                value: Double(characterStore.youthGroupMemberCount),
                total: Double(YouthGroupEngine.takeoverThreshold)
            )
            .tint(Theme.accent)
            Text("\(characterStore.youthGroupMemberCount)/\(YouthGroupEngine.takeoverThreshold) members to rival the main ultras group outright")
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)

            Divider().overlay(Theme.secondaryText.opacity(0.3))

            NavigationLink {
                YouthGroupChatView()
            } label: {
                Label("Group Chat", systemImage: "bubble.left.and.bubble.right.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(Theme.accent)
            }
        }
        .padding(16)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    private var friendshipsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Ultras Friendships", systemImage: "hands.sparkles.fill")
                .font(.headline)
            ForEach(friendClubs) { club in
                HStack {
                    Text(club.name).foregroundStyle(Theme.primaryText)
                    Spacer()
                    Text(club.ultrasGroupName).font(.caption).foregroundStyle(Theme.secondaryText)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
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

            if characterStore.youthGroupRecruitableCrewMembers.isEmpty {
                Text("You've got no one to ask yet — go chat with people from the Crew tab first, then come back here to invite them.")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            } else {
                Button {
                    showRecruitSheet = true
                } label: {
                    Text("Try to Recruit Someone")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(Theme.accentForeground)
                }
            }
        }
        .padding(16)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showRecruitSheet) {
            recruitPickerSheet
        }
    }

    /// Lists every crew member the player has already interacted with
    /// (and isn't already in the group) to pick a specific recruit target
    /// from — see `CharacterStore.youthGroupRecruitableCrewMembers`.
    private var recruitPickerSheet: some View {
        NavigationStack {
            List(characterStore.youthGroupRecruitableCrewMembers) { member in
                Button {
                    showRecruitSheet = false
                    lastRecruitedMemberName = member.name
                    lastRecruitSucceeded = characterStore.recruitToYouthGroup(memberId: member.id)
                    showRecruitResult = true
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(member.name).font(.headline).foregroundStyle(Theme.primaryText)
                        Text(member.rank.displayName).font(.caption).foregroundStyle(Theme.secondaryText)
                    }
                }
                .listRowBackground(Theme.cardBackground)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Ask Someone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showRecruitSheet = false }
                }
            }
        }
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
