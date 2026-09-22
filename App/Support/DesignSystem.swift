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

/// Backs `Theme`'s club-themed colors. A small `@Observable` singleton
/// rather than a `@State`/`@Environment` value, so every one of the app's
/// existing `Theme.accent` call sites picks up a change immediately with
/// no changes needed at the call site — reading any `@Observable`
/// instance's properties during a view's `body` registers as a normal
/// Observation dependency regardless of how the instance was obtained.
@Observable
private final class ThemeState {
    static let shared = ThemeState()

    var accent = Theme.defaultAccent
    var accentSecondary = Theme.defaultAccent
    var accentForeground = Color.white

    private init() {}
}

/// A dark, "stadium at night" palette shared across the app. `background`,
/// `cardBackground`, and the text colors stay fixed for readability no
/// matter the club — only `accent`/`accentSecondary` retheme, to the
/// player's favorite club's colors once a character exists (see
/// `applyClubColors`, called by `CharacterStore` whenever the active
/// character changes), falling back to a neutral red before then.
enum Theme {
    static let background = Color(red: 0.05, green: 0.06, blue: 0.09)
    static let cardBackground = Color(red: 0.10, green: 0.11, blue: 0.15)
    static let primaryText = Color.white
    static let secondaryText = Color(white: 0.7)

    static let defaultAccent = Color(red: 0.85, green: 0.22, blue: 0.24)

    static var accent: Color { ThemeState.shared.accent }
    static var accentSecondary: Color { ThemeState.shared.accentSecondary }
    /// A legible color to draw text/icons in on top of `accent` — white or
    /// black depending on how bright the accent color is, since a club's
    /// primary color can land anywhere from near-black to near-white.
    static var accentForeground: Color { ThemeState.shared.accentForeground }

    /// The player's own crew's colors — used for generic chant/tifo/crew
    /// flavor art, independent of whichever real club they follow.
    static let crewPrimaryHex = "#B3121B"
    static let crewSecondaryHex = "#111111"

    static func applyClubColors(primaryHex: String, secondaryHex: String) {
        ThemeState.shared.accent = Color(hex: primaryHex)
        ThemeState.shared.accentSecondary = Color(hex: secondaryHex)
        ThemeState.shared.accentForeground = contrastingForeground(forHex: primaryHex)
    }

    /// Back to the neutral default — used when there's no active character
    /// (the save-slot picker, or before one's been created yet).
    static func resetToDefaultColors() {
        ThemeState.shared.accent = defaultAccent
        ThemeState.shared.accentSecondary = defaultAccent
        ThemeState.shared.accentForeground = .white
    }

    /// White or black, whichever reads more clearly on top of `hex` — a
    /// standard relative-luminance threshold.
    private static func contrastingForeground(forHex hex: String) -> Color {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if sanitized.hasPrefix("#") { sanitized.removeFirst() }
        guard sanitized.count == 6, let value = UInt64(sanitized, radix: 16) else { return .white }

        let red = Double((value & 0xFF0000) >> 16) / 255
        let green = Double((value & 0x00FF00) >> 8) / 255
        let blue = Double(value & 0x0000FF) / 255
        let luminance = 0.299 * red + 0.587 * green + 0.114 * blue
        return luminance > 0.6 ? .black : .white
    }
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
            .foregroundStyle(Theme.accentForeground)
    }
}
