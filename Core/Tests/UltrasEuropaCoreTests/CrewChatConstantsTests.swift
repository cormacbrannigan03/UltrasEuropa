import XCTest
@testable import UltrasEuropaCore

final class CrewChatConstantsTests: XCTestCase {

    func testEveryTopicHasExactlyTwentyResponses() {
        for topic in ChatTopic.allCases {
            XCTAssertEqual(
                CrewChatConstants.responses[topic]?.count, 20,
                "\(topic) should have exactly 20 responses"
            )
        }
    }

    func testTotalResponseCountIsOneHundred() {
        let total = ChatTopic.allCases.reduce(0) { $0 + (CrewChatConstants.responses[$1]?.count ?? 0) }
        XCTAssertEqual(total, 100)
    }

    func testAllResponsesWithinATopicAreUnique() {
        for topic in ChatTopic.allCases {
            let pool = CrewChatConstants.responses[topic] ?? []
            XCTAssertEqual(Set(pool).count, pool.count, "\(topic) has duplicate lines")
        }
    }

    func testRandomResponseComesFromThePool() {
        var generator = SeededGenerator(seed: 1)
        for topic in ChatTopic.allCases {
            let response = CrewChatConstants.randomResponse(for: topic, using: &generator)
            XCTAssertTrue(CrewChatConstants.responses[topic]?.contains(response) ?? false)
        }
    }

    func testRandomResponseAvoidsImmediateRepeatWhenPossible() {
        let topic = ChatTopic.lastMatch
        var seedGenerator = SeededGenerator(seed: 2)
        let first = CrewChatConstants.randomResponse(for: topic, using: &seedGenerator)

        var sawDifferentResponse = false
        for seed in 0..<50 {
            var generator = SeededGenerator(seed: UInt64(seed + 1000))
            let next = CrewChatConstants.randomResponse(for: topic, excluding: first, using: &generator)
            if next != first { sawDifferentResponse = true }
        }
        XCTAssertTrue(sawDifferentResponse, "Expected at least one different response across many seeds")
    }

    func testEveryPromptTextIsNonEmpty() {
        for topic in ChatTopic.allCases {
            XCTAssertFalse(topic.promptText.isEmpty)
            XCTAssertFalse(topic.displayName.isEmpty)
        }
    }
}
