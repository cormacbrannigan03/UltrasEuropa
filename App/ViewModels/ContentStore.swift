import Foundation
import Observation

/// Thin `@Observable` wrapper so `ContentRepository` (which never changes
/// after launch) can be handed around the SwiftUI environment like any
/// other store.
@Observable
final class ContentStore {
    let repository: ContentRepository

    init(repository: ContentRepository = .loadFromBundle()) {
        self.repository = repository
    }
}
