import SwiftUI
import UltrasEuropaCore

extension Color {
    /// Parses a "#RRGGBB" (or "RRGGBB") hex string. Falls back to gray for
    /// malformed input rather than crashing — bundled content is trusted,
    /// but this keeps a typo in a JSON file from taking down a screen.
    init(hex: String) {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if sanitized.hasPrefix("#") { sanitized.removeFirst() }

        guard sanitized.count == 6, let value = UInt64(sanitized, radix: 16) else {
            self = .gray
            return
        }

        let red = Double((value & 0xFF0000) >> 16) / 255
        let green = Double((value & 0x00FF00) >> 8) / 255
        let blue = Double(value & 0x0000FF) / 255
        self.init(red: red, green: green, blue: blue)
    }
}

/// A dark, "stadium at night" palette shared across the app.
enum Theme {
    static let background = Color(red: 0.05, green: 0.06, blue: 0.09)
    static let cardBackground = Color(red: 0.10, green: 0.11, blue: 0.15)
    static let accent = Color(red: 0.85, green: 0.22, blue: 0.24)
    static let primaryText = Color.white
    static let secondaryText = Color(white: 0.7)

    /// The player's own crew's colors — used for generic chant/tifo/crew
    /// flavor art, independent of whichever real club they follow.
    static let crewPrimaryHex = "#B3121B"
    static let crewSecondaryHex = "#111111"
}

/// Renders in place of a real photo/crest asset when the bundled content
/// has `imageAssetName == nil` — a gradient in the club's own colors with
/// an SF Symbol and optional caption, so galleries and directories look
/// fully themed before any real artwork is added.
struct PlaceholderArt: View {
    let primaryColorHex: String
    let secondaryColorHex: String
    var symbolName: String = "flag.checkered"
    var caption: String? = nil

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: primaryColorHex), Color(hex: secondaryColorHex)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 8) {
                Image(systemName: symbolName)
                    .font(.system(size: 32))
                    .foregroundStyle(.white.opacity(0.85))
                if let caption {
                    Text(caption)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
            }
        }
    }
}

/// A colored pill showing a `Rank`.
struct RankBadge: View {
    let rank: Rank

    var body: some View {
        Text(rank.displayName)
            .font(.subheadline.bold())
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Theme.accent, in: Capsule())
            .foregroundStyle(.white)
    }
}
