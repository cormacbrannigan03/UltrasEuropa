import SwiftUI
import UltrasEuropaCore

/// A chat screen with a friend club's ultras group — the same
/// bubble-and-chips pattern as `CrewChatView`, reusing the same 100
/// generic `ChatTopic` replies (they read just as naturally coming from
/// another club's group as from an individual crew member). Purely
/// social: XP for the friendship comes from
/// `CharacterStore.collaborateWithFriendClub`, a separate explicit
/// action, not from chatting itself.
struct ClubFriendChatView: View {
    let club: Club

    private struct ChatMessage: Identifiable {
        let id = UUID()
        let isPlayer: Bool
        let text: String
    }

    @State private var messages: [ChatMessage] = []
    @State private var lastResponseByTopic: [ChatTopic: String] = [:]

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        if messages.isEmpty {
                            Text("Pick something to say to the \(club.ultrasGroupName) below to get the conversation going.")
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
        .navigationTitle(club.ultrasGroupName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func bubble(for message: ChatMessage) -> some View {
        HStack {
            if message.isPlayer { Spacer(minLength: 40) }
            Text(message.text)
                .padding(10)
                .background(
                    message.isPlayer ? Theme.accent : Theme.cardBackground,
                    in: RoundedRectangle(cornerRadius: 14)
                )
                .foregroundStyle(message.isPlayer ? Theme.accentForeground : Theme.primaryText)
            if !message.isPlayer { Spacer(minLength: 40) }
        }
        .frame(maxWidth: .infinity, alignment: message.isPlayer ? .trailing : .leading)
    }

    private func send(_ topic: ChatTopic) {
        messages.append(ChatMessage(isPlayer: true, text: topic.promptText))

        var generator = SystemRandomNumberGenerator()
        let picked = CrewChatConstants.randomResponse(
            for: topic, excluding: lastResponseByTopic[topic], using: &generator
        )
        lastResponseByTopic[topic] = picked

        messages.append(ChatMessage(isPlayer: false, text: picked))
    }
}

#Preview {
    NavigationStack {
        ClubFriendChatView(club: PreviewSampleData.content.clubs[0])
    }
    .preferredColorScheme(.dark)
}
