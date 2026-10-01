import SwiftUI
import UltrasEuropaCore

/// Lists the fixed set of starter challenges — purely a status board.
/// Nothing here is completable with a tap: each one is marked done by
/// `CharacterStore.completeTask` the moment the player actually does the
/// real thing it describes elsewhere in the app (reading a chant during
/// the match-day chant beat, helping raise a tifo, lighting pyro,
/// traveling to an away fixture, reading a club's history or a rival's
/// profile, browsing the fixture list) — see the call sites of
/// `completeTask` for exactly where each one fires.
struct ChallengesListView: View {
    @Environment(CharacterStore.self) private var characterStore
    @Environment(ContentStore.self) private var contentStore

    var body: some View {
        List(contentStore.repository.tasks) { task in
            let completed = characterStore.isTaskCompleted(task.id)
            HStack {
                VStack(alignment: .leading) {
                    Text(task.title).font(.headline)
                    Text(task.taskDescription).font(.caption).foregroundStyle(Theme.secondaryText)
                }
                Spacer()
                Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(completed ? Theme.accent : Theme.secondaryText)
                    .font(.title2)
            }
            .listRowBackground(Theme.cardBackground)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Challenges")
    }
}
