import SwiftUI
import UltrasEuropaCore

/// A group chat for the player's own youth group — unlike the one-on-one
/// `CrewChatView`, topics here are specifically about organizing for
/// upcoming games (away day plans, meetup times, tifo ideas, transport,
/// pyro). Each reply is attributed to a random recruited member if the
/// group has any (see `CharacterStore.youthGroupNamedMembers`), or to "The
/// Group" generically if it doesn't yet. Message history is local to this
/// screen, same as `CrewChatView` — nothing here is persisted.
struct YouthGroupChatView: View {
    @Environment(CharacterStore.self) private var characterStore

    private struct ChatMessage: Identifiable {
        let id = UUID()
        let isPlayer: Bool
        let speakerName: String?
        let text: String
    }

    @State private var messages: [ChatMessage] = []
    @State private var lastResponseByTopic: [YouthGroupChatTopic: String] = [:]

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        if messages.isEmpty {
                            Text("Lay out a plan for the group below — away days, meetup times, tifo ideas, transport, pyro.")
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
                    ForEach(YouthGroupChatTopic.allCases, id: \.self) { topic in
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
        .navigationTitle("Group Chat")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func bubble(for message: ChatMessage) -> some View {
        HStack {
            if message.isPlayer { Spacer(minLength: 40) }
            VStack(alignment: message.isPlayer ? .trailing : .leading, spacing: 4) {
                if let speakerName = message.speakerName {
                    Text(speakerName).font(.caption2.bold()).foregroundStyle(Theme.secondaryText)
                }
                Text(message.text)
                    .padding(10)
                    .background(
                        message.isPlayer ? Theme.accent : Theme.cardBackground,
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                    .foregroundStyle(message.isPlayer ? Theme.accentForeground : Theme.primaryText)
            }
            if !message.isPlayer { Spacer(minLength: 40) }
        }
        .frame(maxWidth: .infinity, alignment: message.isPlayer ? .trailing : .leading)
    }

    private func send(_ topic: YouthGroupChatTopic) {
        messages.append(ChatMessage(isPlayer: true, speakerName: nil, text: topic.promptText))

        characterStore.sendYouthGroupChatMessage()

        var generator = SystemRandomNumberGenerator()
        let reply = YouthGroupChatConstants.randomResponse(
            for: topic, excluding: lastResponseByTopic[topic], using: &generator
        )
        lastResponseByTopic[topic] = reply

        let speaker = characterStore.youthGroupNamedMembers.randomElement(using: &generator)?.name ?? "The Group"
        messages.append(ChatMessage(isPlayer: false, speakerName: speaker, text: reply))
    }
}

#Preview {
    NavigationStack {
        YouthGroupChatView()
    }
    .environment(PreviewSampleData.characterStore)
    .preferredColorScheme(.dark)
}
