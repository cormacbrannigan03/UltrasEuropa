import XCTest
@testable import UltrasEuropaCore

final class ContentDecodingTests: XCTestCase {

    func testDecodesClub() throws {
        let json = """
        {
            "id": "arsenal", "name": "Arsenal", "city": "London", "country": "England",
            "leagueId": "premier-league", "prestigeTier": 5, "founded": 1886,
            "stadiumName": "Emirates Stadium", "primaryColorHex": "#EF0107",
            "secondaryColorHex": "#FFFFFF", "crestAssetName": null, "history": null
        }
        """.data(using: .utf8)!

        let club = try ContentDecoding.decode(Club.self, from: json)
        XCTAssertEqual(club.id, "arsenal")
        XCTAssertEqual(club.leagueId, "premier-league")
        XCTAssertEqual(club.prestigeTier, 5)
        XCTAssertEqual(club.founded, 1886)
        XCTAssertNil(club.crestAssetName)
        XCTAssertNil(club.history)
    }

    func testDecodesLeague() throws {
        let json = """
        { "id": "premier-league", "name": "Premier League", "country": "England", "rank": 1 }
        """.data(using: .utf8)!

        let league = try ContentDecoding.decode(League.self, from: json)
        XCTAssertEqual(league.id, "premier-league")
        XCTAssertEqual(league.rank, 1)
    }

    func testDecodesMatchWithNullScoresAsUnplayed() throws {
        let json = """
        {
            "id": "m1", "homeClubId": "arsenal", "awayClubId": "chelsea",
            "date": "2026-03-14T19:00:00Z", "competition": "Premier League", "venue": "Emirates Stadium",
            "homeScore": null, "awayScore": null
        }
        """.data(using: .utf8)!

        let match = try ContentDecoding.decode(Match.self, from: json)
        XCTAssertFalse(match.isPlayed)
    }

    func testDecodesMatchWithScoresAsPlayed() throws {
        let json = """
        {
            "id": "m2", "homeClubId": "arsenal", "awayClubId": "chelsea",
            "date": "2026-01-10T19:00:00Z", "competition": "Premier League", "venue": "Emirates Stadium",
            "homeScore": 2, "awayScore": 1
        }
        """.data(using: .utf8)!

        let match = try ContentDecoding.decode(Match.self, from: json)
        XCTAssertTrue(match.isPlayed)
    }

    func testDecodesChant() throws {
        let json = """
        { "id": "chant-one-voice", "title": "One Voice", "lyrics": "We are one voice.", "audioAssetName": null }
        """.data(using: .utf8)!

        let chant = try ContentDecoding.decode(Chant.self, from: json)
        XCTAssertEqual(chant.title, "One Voice")
    }

    func testDecodesTifoPhoto() throws {
        let json = """
        { "id": "tifo-flag-wall", "caption": "A full flag wall.", "imageAssetName": null }
        """.data(using: .utf8)!

        let photo = try ContentDecoding.decode(TifoPhoto.self, from: json)
        XCTAssertEqual(photo.caption, "A full flag wall.")
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

    func testDecodesCrewMember() throws {
        let json = """
        {
            "id": "crew-tommy", "name": "Tommy", "rank": 0,
            "personality": "Eager newcomer",
            "bio": "Turned up to his first match last season and hasn't missed one since."
        }
        """.data(using: .utf8)!

        let member = try ContentDecoding.decode(CrewMember.self, from: json)
        XCTAssertEqual(member.name, "Tommy")
        XCTAssertEqual(member.rank, .regular)
    }

    func testDecodesClothingItem() throws {
        let json = """
        {
            "id": "top-classic-jersey", "name": "Classic Jersey", "slot": "top",
            "description": "A simple jersey in your crew's colors.", "isRangeItem": false
        }
        """.data(using: .utf8)!

        let item = try ContentDecoding.decode(ClothingItem.self, from: json)
        XCTAssertEqual(item.slot, .top)
        XCTAssertEqual(item.clothingDescription, "A simple jersey in your crew's colors.")
        XCTAssertFalse(item.isRangeItem)
    }

    func testDecodesStoreProduct() throws {
        let json = """
        {
            "kind": "riseToTop", "name": "Rise to the Top",
            "description": "Skip straight to Capo, the top rank in the game.",
            "priceDisplay": "$9.99"
        }
        """.data(using: .utf8)!

        let product = try ContentDecoding.decode(StoreProduct.self, from: json)
        XCTAssertEqual(product.kind, .riseToTop)
        XCTAssertEqual(product.itemDescription, "Skip straight to Capo, the top rank in the game.")
        XCTAssertEqual(product.id, product.kind.productID)
    }
}
