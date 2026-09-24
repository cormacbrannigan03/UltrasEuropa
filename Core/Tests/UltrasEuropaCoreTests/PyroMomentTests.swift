import XCTest
@testable import UltrasEuropaCore

final class PyroMomentTests: XCTestCase {

    func testAllCasesHaveNonEmptyDisplayNames() {
        for moment in PyroMoment.allCases {
            XCTAssertFalse(moment.displayName.isEmpty)
        }
    }

    func testExactlyTwoMoments() {
        XCTAssertEqual(PyroMoment.allCases.count, 2)
    }

    func testRawValuesAreStableForPersistence() {
        XCTAssertEqual(PyroMoment.kickoff.rawValue, "kickoff")
        XCTAssertEqual(PyroMoment.afterGoal.rawValue, "afterGoal")
    }
}
