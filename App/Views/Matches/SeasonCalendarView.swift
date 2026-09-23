import SwiftUI
import UltrasEuropaCore

/// The favorite club's fixtures grouped by month, with a "Fast Forward to
/// Next Match" action — the intended way to reach a match day, rather than
/// nudging the season clock forward blindly a day or a week at a time.
struct SeasonCalendarView: View {
    @Environment(CharacterStore.self) private var characterStore

    private var matches: [Match] {
        guard let favoriteClub = characterStore.favoriteClub else { return [] }
        return characterStore.matchesForClub(favoriteClub.id).sorted { $0.date < $1.date }
    }

    private var nextMatch: Match? {
        matches.first { !$0.isPlayed }
    }

    /// Matches grouped by month — safe to build by walking the
    /// already-date-sorted list and starting a new group whenever the
    /// (year, month) changes, since a month never reappears out of order.
    private var monthGroups: [(month: String, matches: [Match])] {
        let calendar = Calendar.current
        var groups: [(String, [Match])] = []
        var currentKey: DateComponents?
        var currentMatches: [Match] = []

        for match in matches {
            let key = calendar.dateComponents([.year, .month], from: match.date)
            if key != currentKey {
                if let currentKey {
                    groups.append((monthLabel(for: currentKey), currentMatches))
                }
                currentKey = key
                currentMatches = [match]
            } else {
                currentMatches.append(match)
            }
        }
        if let currentKey {
            groups.append((monthLabel(for: currentKey), currentMatches))
        }
        return groups
    }

    private func monthLabel(for components: DateComponents) -> String {
        guard let date = Calendar.current.date(from: components) else { return "" }
        return date.formatted(.dateTime.month(.wide).year())
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Season Clock").font(.headline)
                    Text(characterStore.simulatedDate, style: .date)
                        .font(.subheadline.bold())
                        .foregroundStyle(Theme.accent)

                    if let nextMatch {
                        Button {
                            characterStore.simulateForward(to: nextMatch.date)
                        } label: {
                            Label("Fast Forward to Next Match", systemImage: "forward.end.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.accent)
                    } else {
                        Text("No more matches left to fast forward to this season.")
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(Theme.cardBackground)

            ForEach(monthGroups, id: \.month) { group in
                Section(group.month) {
                    ForEach(group.matches) { match in
                        NavigationLink(value: match) {
                            CalendarMatchRow(
                                match: match,
                                isToday: Calendar.current.isDate(match.date, inSameDayAs: characterStore.simulatedDate)
                            )
                        }
                    }
                    .listRowBackground(Theme.cardBackground)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Season Calendar")
        .navigationDestination(for: Match.self) { match in
            MatchDetailView(match: match)
        }
    }
}

private struct CalendarMatchRow: View {
    let match: Match
    let isToday: Bool

    @Environment(ContentStore.self) private var contentStore
    @Environment(CharacterStore.self) private var characterStore

    private var isHome: Bool {
        match.homeClubId == characterStore.favoriteClub?.id
    }

    private var opponentName: String {
        let opponentId = isHome ? match.awayClubId : match.homeClubId
        return contentStore.repository.club(id: opponentId)?.name ?? opponentId
    }

    private var category: MatchCategory { characterStore.matchCategory(for: match) }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(isHome ? "vs" : "@") \(opponentName)").font(.subheadline.bold())
                HStack(spacing: 6) {
                    Text(match.date, style: .date).font(.caption).foregroundStyle(Theme.secondaryText)
                    Text("·").font(.caption).foregroundStyle(Theme.secondaryText)
                    Text(category.displayName).font(.caption).foregroundStyle(Theme.secondaryText)
                }
            }
            Spacer()
            if isToday {
                Text("Today")
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.accent, in: Capsule())
                    .foregroundStyle(Theme.accentForeground)
            } else if match.isPlayed, let h = match.homeScore, let a = match.awayScore {
                Text("\(h) - \(a)").font(.subheadline.bold())
            } else {
                Text("Upcoming").font(.caption).foregroundStyle(Theme.secondaryText)
            }
        }
    }
}
