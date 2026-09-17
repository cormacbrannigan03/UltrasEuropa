import SwiftUI

/// Shows the in-game "season clock" and lets the player advance it — see
/// `CharacterStore.simulatedDate`/`simulateDays`. Matches only get results
/// (and tickets only go on sale) once the season clock reaches them, so
/// this is the main way to move the game forward without waiting on the
/// device's real calendar.
struct SeasonClockCard: View {
    let simulatedDate: Date
    let onSimulateDay: () -> Void
    let onSimulateWeek: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Season Clock").font(.headline)
            Text(simulatedDate, style: .date)
                .font(.subheadline.bold())
                .foregroundStyle(Theme.accent)

            HStack(spacing: 12) {
                Button(action: onSimulateDay) {
                    Label("+1 Day", systemImage: "forward.frame.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(action: onSimulateWeek) {
                    Label("+1 Week", systemImage: "forward.end.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .tint(Theme.accent)
        }
        .padding(16)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    SeasonClockCard(simulatedDate: .now, onSimulateDay: {}, onSimulateWeek: {})
        .padding()
        .background(Theme.background)
        .preferredColorScheme(.dark)
}
