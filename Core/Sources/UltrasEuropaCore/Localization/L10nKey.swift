import Foundation

/// A piece of interface "chrome" text that has been translated across all
/// of `AppLanguage`. Deliberately a small, curated set — the tab bar plus a
/// couple of key Dashboard links — rather than every string in the app;
/// see `LocalizedStrings` for the translation table and the coverage note.
public enum L10nKey: String, CaseIterable, Sendable {
    case tabDashboard
    case tabClubs
    case tabMatches
    case tabTable
    case tabGallery
    case seasonCalendar
    case store
    case language
}
