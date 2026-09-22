import Foundation

/// The terminal, mutually-exclusive choice available once the youth group
/// reaches `YouthGroupEngine.takeoverThreshold` members — see
/// `CharacterStore.mergeYouthGroupWithMainUltras`/`takeOverMainUltrasGroup`.
/// `.none` is the ordinary in-progress state; once either ending is
/// chosen, recruiting stops mattering — the story there is finished.
public enum YouthGroupOutcome: String, Codable, Hashable, Sendable {
    case none
    case merged
    case tookOver
}
