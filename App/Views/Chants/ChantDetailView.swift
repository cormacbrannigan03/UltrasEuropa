import SwiftUI
import UltrasEuropaCore

struct ChantDetailView: View {
    let chant: Chant

    @Environment(CharacterStore.self) private var characterStore
    @State private var showOutcome = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(chant.title).font(.title.bold())

                Text(chant.lyrics)
                    .font(.body)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))

                Button {
                    characterStore.recordActivity(.participateInChant)
                    showOutcome = true
                } label: {
                    Text("Participate")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                }
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("Chant")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Chant", isPresented: $showOutcome, presenting: characterStore.lastOutcome) { _ in
            Button("OK") { characterStore.lastOutcome = nil }
        } message: { outcome in
            Text(outcome.displayText)
        }
    }
}
