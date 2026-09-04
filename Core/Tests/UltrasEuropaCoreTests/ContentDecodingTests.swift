import XCTest
@testable import UltrasEuropaCore

final class ContentDecodingTests: XCTestCase {

    func testDecodesClub() throws {
        let json = """
        {
            "id": "rotstadt", "name": "FC Rotstadt", "city": "Rotstadt", "country": "Germany",
            "founded": 1904, "stadiumName": "Rotstadion", "primaryColorHex": "#B3121B",
            "secondaryColorHex": "#111111", "crestAssetName": null,
            "history": "Founded by dockworkers in 1904."
        }
        """.data(using: .utf8)!

        let club = try ContentDecoding.decode(Club.self, from: json)
        XCTAssertEqual(club.id, "rotstadt")
        XCTAssertEqual(club.founded, 1904)
        XCTAssertNil(club.crestAssetName)
    }

    func testDecodesUltrasGroupWithDescriptionKey() throws {
        let json = """
        {
            "id": "rotstadt-brigade", "clubId": "rotstadt", "name": "Rotstadt Brigade '58",
            "founded": 1958, "symbols": ["Crossed flags", "Black star"], "colors": ["Red", "Black"],
            "description": "The main ultras group behind the south stand."
        }
        """.data(using: .utf8)!

        let group = try ContentDecoding.decode(UltrasGroup.self, from: json)
        XCTAssertEqual(group.groupDescription, "The main ultras group behind the south stand.")
    }

    func testDecodesMatchWithNullScoresAsUnplayed() throws {
        let json = """
        {
            "id": "m1", "homeClubId": "rotstadt", "awayClubId": "portovento",
            "date": "2026-03-14T19:00:00Z", "competition": "Euro Cup", "venue": "Rotstadion",
            "homeScore": null, "awayScore": null
        }
        """.data(using: .utf8)!

        let match = try ContentDecoding.decode(Match.self, from: json)
        XCTAssertFalse(match.isPlayed)
    }

    func testDecodesMatchWithScoresAsPlayed() throws {
        let json = """
        {
            "id": "m2", "homeClubId": "rotstadt", "awayClubId": "portovento",
            "date": "2026-01-10T19:00:00Z", "competition": "Euro Cup", "venue": "Rotstadion",
            "homeScore": 2, "awayScore": 1
        }
        """.data(using: .utf8)!

        let match = try ContentDecoding.decode(Match.self, from: json)
        XCTAssertTrue(match.isPlayed)
    }

    func testDecodesAchievementCriteria() throws {
        let json = """
        {
            "id": "pyro-veteran", "name": "Pyro Veteran",
            "description": "Ran 10 pyro displays.",
            "criteria": { "kind": "activityCount", "activityType": "doPyroChallenge", "threshold": 10 }
        }
        """.data(using: .utf8)!

        let achievement = try ContentDecoding.decode(Achievement.self, from: json)
        XCTAssertEqual(achievement.criteria.kind, .activityCount)
        XCTAssertEqual(achievement.criteria.activityType, .doPyroChallenge)
        XCTAssertEqual(achievement.criteria.threshold, 10)
    }

    func testDecodesInventoryItem() throws {
        let json = """
        {
            "id": "classic-scarf", "name": "Classic Scarf", "category": "scarf",
            "description": "A scarf every fan starts with.",
            "unlockCriteria": { "kind": "activityCount", "activityType": "attendMatch", "threshold": 1 }
        }
        """.data(using: .utf8)!

        let item = try ContentDecoding.decode(InventoryItem.self, from: json)
        XCTAssertEqual(item.category, .scarf)
        XCTAssertEqual(item.itemDescription, "A scarf every fan starts with.")
    }

    func testDecodesChallengeTask() throws {
        let json = """
        {
            "id": "learn-a-chant", "title": "Learn a Chant",
            "description": "Read through a chant's lyrics.", "relatedClubId": null
        }
        """.data(using: .utf8)!

        let task = try ContentDecoding.decode(ChallengeTask.self, from: json)
        XCTAssertEqual(task.title, "Learn a Chant")
        XCTAssertNil(task.relatedClubId)
    }
}
