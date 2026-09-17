import XCTest
@testable import UltrasEuropaCore

final class TravelModeTests: XCTestCase {

    func testPreferredModeIsDeterministic() {
        let first = TravelMode.preferred(byMemberId: "crew-tommy")
        let second = TravelMode.preferred(byMemberId: "crew-tommy")
        XCTAssertEqual(first, second)
    }

    func testDifferentMembersCanPreferDifferentModes() {
        let modes = Set(["crew-tommy", "crew-dana", "crew-iggy", "crew-priya", "crew-marcus"].map {
            TravelMode.preferred(byMemberId: $0)
        })
        XCTAssertEqual(modes.count, 2, "Expected both bus and train to show up across a handful of members")
    }
}
