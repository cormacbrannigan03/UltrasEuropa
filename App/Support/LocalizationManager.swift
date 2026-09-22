import Foundation
import Observation
import UltrasEuropaCore

/// The app's current display language. An `@Observable` singleton — the
/// same pattern `ThemeState` uses for club colors — so `Theme`-style call
/// sites (`LocalizationManager.shared.string(.tabDashboard)`) pick up a
/// change immediately without any `@Environment` plumbing, and persisted
/// to `UserDefaults` as a per-device preference (like `SaveSlotStore`'s
/// active-slot key) rather than per-save state.
@Observable
final class LocalizationManager {
    static let shared = LocalizationManager()

    private static let storageKey = "UltrasEuropa.appLanguage"

    private(set) var currentLanguage: AppLanguage

    private init() {
        if let stored = UserDefaults.standard.string(forKey: Self.storageKey),
            let language = AppLanguage(rawValue: stored)
        {
            currentLanguage = language
        } else {
            currentLanguage = .english
        }
    }

    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: Self.storageKey)
    }

    func string(_ key: L10nKey) -> String {
        LocalizedStrings.string(key, language: currentLanguage)
    }
}
