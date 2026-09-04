import SwiftUI
import UltrasEuropaCore

struct RankProgressCard: View {
    let rank: Rank
    let progress: RankProgress?
    let xpMultiplier: Double
    let achievementName: (String) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let progress {
                Text("Progress to \(progress.rank.displayName)")
                    .font(.headline)

                if let multiplierNote {
                    Text(multiplierNote)
                        .font(.caption)
                        .foregroundStyle(Theme.accent)
                }

                ProgressRow(label: "XP", current: progress.xpProgress, total: progress.xpNeeded)

                if progress.matchesAttendedNeeded > 0 {
                    ProgressRow(
                        label: "Matches Attended",
                        current: progress.matchesAttendedProgress,
                        total: progress.matchesAttendedNeeded
                    )
                }
                if progress.activityDiversityNeeded > 0 {
                    ProgressRow(
                        label: "Activity Variety",
                        current: progress.activityDiversityProgress,
                        total: progress.activityDiversityNeeded
                    )
                }
                if progress.streakNeeded > 0 {
                    ProgressRow(
                        label: "Loyalty Streak (days)",
                        current: progress.streakProgress,
                        total: progress.streakNeeded
                    )
                }

                if !progress.missingAchievementIDs.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Still needed:")
                            .font(.caption.bold())
                            .foregroundStyle(Theme.secondaryText)
                        ForEach(Array(progress.missingAchievementIDs).sorted(), id: \.self) { id in
                            Label(achievementName(id), systemImage: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                    .padding(.top, 4)
                }
            } else {
                Text("You've reached the top of the ladder: Capo.")
                    .font(.headline)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    private var multiplierNote: String? {
        if xpMultiplier > 1.001 {
            return String(format: "Your club's size makes this tougher — %.1f× the XP a smaller club would need.", xpMultiplier)
        } else if xpMultiplier < 0.999 {
            let discount = Int(((1 - xpMultiplier) * 100).rounded())
            return "Your club's size makes this easier — \(discount)% less XP needed than a top club."
        } else {
            return nil
        }
    }
}

private struct ProgressRow: View {
    let label: String
    let current: Int
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).font(.caption).foregroundStyle(Theme.secondaryText)
                Spacer()
                Text("\(current)/\(total)").font(.caption.bold())
            }
            ProgressView(value: total > 0 ? Double(current) / Double(total) : 1)
                .tint(Theme.accent)
        }
    }
}
