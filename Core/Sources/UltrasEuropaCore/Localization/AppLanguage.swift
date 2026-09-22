import Foundation

/// A language the app's interface can be displayed in. Covers the 24
/// official languages of the European Union plus Norwegian, Turkish, and
/// Serbian — chosen so every nation with a league in `leagues.json` has its
/// language represented, alongside the full official EU list, for a
/// defensible "available in all European languages" scope.
public enum AppLanguage: String, CaseIterable, Codable, Sendable, Identifiable {
    case english
    case bulgarian
    case croatian
    case czech
    case danish
    case dutch
    case estonian
    case finnish
    case french
    case german
    case greek
    case hungarian
    case irish
    case italian
    case latvian
    case lithuanian
    case maltese
    case norwegian
    case polish
    case portuguese
    case romanian
    case serbian
    case slovak
    case slovenian
    case spanish
    case swedish
    case turkish

    public var id: String { rawValue }

    /// ISO 639-1 code, used as the `Locale` identifier for this language.
    public var isoCode: String {
        switch self {
        case .english: return "en"
        case .bulgarian: return "bg"
        case .croatian: return "hr"
        case .czech: return "cs"
        case .danish: return "da"
        case .dutch: return "nl"
        case .estonian: return "et"
        case .finnish: return "fi"
        case .french: return "fr"
        case .german: return "de"
        case .greek: return "el"
        case .hungarian: return "hu"
        case .irish: return "ga"
        case .italian: return "it"
        case .latvian: return "lv"
        case .lithuanian: return "lt"
        case .maltese: return "mt"
        case .norwegian: return "no"
        case .polish: return "pl"
        case .portuguese: return "pt"
        case .romanian: return "ro"
        case .serbian: return "sr"
        case .slovak: return "sk"
        case .slovenian: return "sl"
        case .spanish: return "es"
        case .swedish: return "sv"
        case .turkish: return "tr"
        }
    }

    /// The name of the language, written in that language itself.
    public var nativeName: String {
        switch self {
        case .english: return "English"
        case .bulgarian: return "Български"
        case .croatian: return "Hrvatski"
        case .czech: return "Čeština"
        case .danish: return "Dansk"
        case .dutch: return "Nederlands"
        case .estonian: return "Eesti"
        case .finnish: return "Suomi"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .greek: return "Ελληνικά"
        case .hungarian: return "Magyar"
        case .irish: return "Gaeilge"
        case .italian: return "Italiano"
        case .latvian: return "Latviešu"
        case .lithuanian: return "Lietuvių"
        case .maltese: return "Malti"
        case .norwegian: return "Norsk"
        case .polish: return "Polski"
        case .portuguese: return "Português"
        case .romanian: return "Română"
        case .serbian: return "Српски"
        case .slovak: return "Slovenčina"
        case .slovenian: return "Slovenščina"
        case .spanish: return "Español"
        case .swedish: return "Svenska"
        case .turkish: return "Türkçe"
        }
    }

    /// A flag emoji representing the language's home nation — shown as the
    /// tappable emblem on the home screen.
    public var flagEmoji: String {
        switch self {
        case .english: return "🇬🇧"
        case .bulgarian: return "🇧🇬"
        case .croatian: return "🇭🇷"
        case .czech: return "🇨🇿"
        case .danish: return "🇩🇰"
        case .dutch: return "🇳🇱"
        case .estonian: return "🇪🇪"
        case .finnish: return "🇫🇮"
        case .french: return "🇫🇷"
        case .german: return "🇩🇪"
        case .greek: return "🇬🇷"
        case .hungarian: return "🇭🇺"
        case .irish: return "🇮🇪"
        case .italian: return "🇮🇹"
        case .latvian: return "🇱🇻"
        case .lithuanian: return "🇱🇹"
        case .maltese: return "🇲🇹"
        case .norwegian: return "🇳🇴"
        case .polish: return "🇵🇱"
        case .portuguese: return "🇵🇹"
        case .romanian: return "🇷🇴"
        case .serbian: return "🇷🇸"
        case .slovak: return "🇸🇰"
        case .slovenian: return "🇸🇮"
        case .spanish: return "🇪🇸"
        case .swedish: return "🇸🇪"
        case .turkish: return "🇹🇷"
        }
    }
}
