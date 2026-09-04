import Foundation

/// A discrete mission the player can complete (e.g. "Learn a chant").
/// Named `ChallengeTask` rather than `Task` to avoid colliding with Swift's
/// concurrency `Task` type.
public struct ChallengeTask: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let taskDescription: String
    public let relatedClubId: String?

    public init(
        id: String,
        title: String,
        taskDescription: String,
        relatedClubId: String? = nil
    ) {
        self.id = id
        self.title = title
        self.taskDescription = taskDescription
        self.relatedClubId = relatedClubId
    }

    enum CodingKeys: String, CodingKey {
        case id, title, relatedClubId
        case taskDescription = "description"
    }
}
