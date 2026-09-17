import SwiftUI
import UltrasEuropaCore

/// The Matches tab — the favorite club's own fixtures and results (see
/// `SeasonScheduleGenerator` — these are not real fixtures). To browse any
/// other club's schedule, use the Clubs tab instead (`ClubDetailView`).
struct MatchesHomeView: View {
    @Environment(CharacterStore.self) private var characterStore

    var body: some View {
        Group {
            if let favoriteClub = characterStore.favoriteClub {
                MatchScheduleView(
                    title: favoriteClub.name,
                    matches: characterStore.matchesForClub(favoriteClub.id)
                )
            } else {
                Text("No favorite club yet.")
                    .foregroundStyle(Theme.secondaryText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.background)
                    .navigationTitle("Matches")
            }
        }
    }
}
