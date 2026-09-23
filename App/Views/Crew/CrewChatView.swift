import SwiftUI
import UltrasEuropaCore

/// A real back-and-forth chat screen with a crew member — replaces the
/// old single-tap "Chat" alert. There's no free-text input; instead the
/// player picks from a handful of `ChatTopic` quick-reply chips, which
/// still resolves the same underlying `CrewInteractionEngine` roll (bond
/// score, XP) the other interaction types use, but replies with one of
/// `CrewChatConstants`'s 100 generic lines instead of a flat two-line
/// outcome message, so the conversation actually feels varied.
struct CrewChatView: View {
    let member: CrewMember

    @Environment(CharacterStore.self) private var characterStore

    private struct ChatMessage: Identifiable {
        let id = UUID()
        let isPlayer: Bool
        let text: String
        let bondDelta: Int?
    }

    @State private var messages: [ChatMessage] = []
    @State private var lastResponseByTopic: [ChatTopic: String] = [:]

    private var isAcknowledged: Bool {
        CrewInteractionConstants.acknowledges(memberRank: member.rank, playerRank: characterStore.rank)
    }
    private var requiredRank: Rank? { Rank(rawValue: member.rank.rawValue - 1) }

    var body: some View {
        VStack(spacing: 0) {
            if !isAcknowledged, let requiredRank {
                Label(
                    "\(member.name) won't really open up until you reach \(requiredRank.displayName).",
                    systemImage: "eye.slash"
                )
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.cardBackground)
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        if messages.isEmpty {
                            Text("Pick something to say to \(member.name) below to get the conversation going.")
                                .font(.caption)
                                .foregroundStyle(Theme.secondaryText)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        ForEach(messages) { message in
                            bubble(for: message).id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) {
                    if let last = messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            Divider().overlay(Theme.secondaryText.opacity(0.3))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ChatTopic.allCases, id: \.self) { topic in
                        Button {
                            send(topic)
                        } label: {
                            Text(topic.displayName)
                                .font(.caption.bold())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Theme.accent, in: Capsule())
                                .foregroundStyle(Theme.accentForeground)
                        }
                    }
                }
                .padding(12)
            }
        }
        .background(Theme.background)
        .navigationTitle(member.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func bubble(for message: ChatMessage) -> some View {
        HStack {
            if message.isPlayer { Spacer(minLength: 40) }
            VStack(alignment: message.isPlayer ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(10)
                    .background(
                        message.isPlayer ? Theme.accent : Theme.cardBackground,
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                    .foregroundStyle(message.isPlayer ? Theme.accentForeground : Theme.primaryText)
                if let delta = message.bondDelta, delta != 0 {
                    Text("Relationship \(delta > 0 ? "+" : "")\(delta)")
                        .font(.caption2)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            if !message.isPlayer { Spacer(minLength: 40) }
        }
        .frame(maxWidth: .infinity, alignment: message.isPlayer ? .trailing : .leading)
    }

    private func send(_ topic: ChatTopic) {
        messages.append(ChatMessage(isPlayer: true, text: topic.promptText, bondDelta: nil))

        let result = characterStore.interact(with: member, type: .chat)

        let reply: String
        if !isAcknowledged {
            reply = result?.outcome.message ?? "\(member.name) doesn't seem interested in talking right now."
        } else {
            var generator = SystemRandomNumberGenerator()
            let picked = CrewChatConstants.randomResponse(
                for: topic, excluding: lastResponseByTopic[topic], using: &generator
            )
            lastResponseByTopic[topic] = picked
            reply = picked
        }

        messages.append(ChatMessage(isPlayer: false, text: reply, bondDelta: result?.outcome.bondDelta))
    }
}

#Preview {
    NavigationStack {
        CrewChatView(member: PreviewSampleData.content.crewMembers[0])
    }
    .environment(PreviewSampleData.characterStore)
    .preferredColorScheme(.dark)
}
