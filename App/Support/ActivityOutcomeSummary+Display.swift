import Foundation
import UltrasEuropaCore

extension ActivityOutcomeSummary {
    /// Human-readable summary for a toast/alert after a single activity —
    /// used everywhere except match attendance, which combines several
    /// activities at once and builds its own summary (see `MatchDetailView`).
    var displayText: String {
        var lines = ["+\(xpAwarded) XP"]
        if didRankUp {
            lines.append("Ranked up to \(newRank.displayName)!")
        }
        if !newlyUnlockedAchievements.isEmpty {
            lines.append("Unlocked: " + newlyUnlockedAchievements.map(\.name).joined(separator: ", "))
        }
        if !newlyUnlockedItems.isEmpty {
            lines.append("New item: " + newlyUnlockedItems.map(\.name).joined(separator: ", "))
        }
        return lines.joined(separator: "\n")
    }
}
