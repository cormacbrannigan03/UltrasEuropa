import SwiftUI
import UltrasEuropaCore

/// Read-only lyrics reference — joining in a chant for XP now happens
/// during a specific match's cutscene (`MatchDayCutsceneView`), not from
/// here. Every match has one chant assigned (see
/// `ContentRepository.chantOfTheDay`), so browse here to learn the words,
/// then sing along when you're actually at a game.
struct ChantDetailView: View {
    let chant: Chant

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(chant.title).font(.title.bold())

                Text(chant.lyrics)
                    .font(.body)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))

                Text("Join in when this comes up during a match day — check the Matches tab for your next game.")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("Chant")
        .navigationBarTitleDisplayMode(.inline)
    }
}
