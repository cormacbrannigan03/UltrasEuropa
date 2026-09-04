import SwiftUI
import UltrasEuropaCore

struct ChallengesListView: View {
    @Environment(CharacterStore.self) private var characterStore
    @Environment(ContentStore.self) private var contentStore
    @State private var showOutcome = false

    var body: some View {
        List(contentStore.repository.tasks) { task in
            let completed = characterStore.isTaskCompleted(task.id)
            HStack {
                VStack(alignment: .leading) {
                    Text(task.title).font(.headline)
                    Text(task.taskDescription).font(.caption).foregroundStyle(Theme.secondaryText)
                }
                Spacer()
                Button {
                    characterStore.completeTask(task.id)
                    showOutcome = true
                } label: {
                    Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(completed ? Theme.accent : Theme.secondaryText)
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .disabled(completed)
            }
            .listRowBackground(Theme.cardBackground)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Challenges")
        .alert("Challenge Complete", isPresented: $showOutcome, presenting: characterStore.lastOutcome) { _ in
            Button("OK") { characterStore.lastOutcome = nil }
        } message: { outcome in
            Text(outcome.displayText)
        }
    }
}
