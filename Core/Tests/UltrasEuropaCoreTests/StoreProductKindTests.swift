import XCTest
@testable import UltrasEuropaCore

final class StoreProductKindTests: XCTestCase {

    func testEveryKindRoundTripsThroughItsProductID() {
        for kind in StoreProductKind.allCases {
            XCTAssertEqual(StoreProductKind.forProductID(kind.productID), kind)
        }
    }

    func testProductIDsAreAllDistinct() {
        let ids = StoreProductKind.allCases.map(\.productID)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    func testUnknownProductIDResolvesToNil() {
        XCTAssertNil(StoreProductKind.forProductID("com.someoneelse.app.unrelatedProduct"))
    }
}
