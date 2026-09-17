import XCTest
@testable import UltrasEuropaCore

final class UltrasGroupMembershipStageTests: XCTestCase {

    func testStageMapsToExistingRankThresholds() {
        XCTAssertEqual(UltrasGroupMembershipStage.forRank(.regular), .notNoticed)
        XCTAssertEqual(UltrasGroupMembershipStage.forRank(.youngUltra), .notNoticed)
        XCTAssertEqual(UltrasGroupMembershipStage.forRank(.ultraGroup), .invitedHomeGames)
        XCTAssertEqual(UltrasGroupMembershipStage.forRank(.leadUltra), .invitedAwayGames)
        XCTAssertEqual(UltrasGroupMembershipStage.forRank(.capo), .fullMember)
    }

    func testNoticedStageHasNoAnnouncement() {
        XCTAssertNil(UltrasGroupMembershipStage.notNoticed.invitationAnnouncement(clubName: "Arsenal"))
    }

    func testOtherStagesAnnounceAndMentionClubName() {
        for stage: UltrasGroupMembershipStage in [.invitedHomeGames, .invitedAwayGames, .fullMember] {
            let announcement = stage.invitationAnnouncement(clubName: "Arsenal")
            XCTAssertNotNil(announcement)
            XCTAssertTrue(announcement?.contains("Arsenal") ?? false)
        }
    }

    func testClubUltrasGroupNameIsGeneric() {
        let club = Club(
            id: "arsenal", name: "Arsenal", city: "London", country: "England",
            leagueId: "premier-league", founded: 1886, stadiumName: "Emirates Stadium",
            primaryColorHex: "#EF0107", secondaryColorHex: "#FFFFFF"
        )
        XCTAssertEqual(club.ultrasGroupName, "Arsenal Ultras")
    }

    func testBiggerClubsNeedMoreLoyaltyForASeasonTicket() {
        let smallClubThreshold = ProgressionConstants.loyaltyThresholdForSeasonTicket(prestigeTier: 1)
        let giantClubThreshold = ProgressionConstants.loyaltyThresholdForSeasonTicket(prestigeTier: 5)
        XCTAssertLessThan(smallClubThreshold, giantClubThreshold)
    }

    func testHasEarnedSeasonTicketBoundary() {
        let threshold = ProgressionConstants.loyaltyThresholdForSeasonTicket(prestigeTier: 3)
        XCTAssertFalse(ProgressionConstants.hasEarnedSeasonTicket(loyalty: threshold - 1, prestigeTier: 3))
        XCTAssertTrue(ProgressionConstants.hasEarnedSeasonTicket(loyalty: threshold, prestigeTier: 3))
        XCTAssertTrue(ProgressionConstants.hasEarnedSeasonTicket(loyalty: threshold + 100, prestigeTier: 3))
    }
}
