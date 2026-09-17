import Foundation

/// What a real-money store purchase actually grants. Each case is a
/// permanent, one-time entitlement (not a consumable) applied by
/// `CharacterStore.grantStorePurchase` on the App layer — Core only knows
/// the *shape* of the catalog, not how an entitlement is persisted or
/// enforced.
public enum StoreProductKind: String, Codable, CaseIterable, Hashable, Sendable {
    case unlockAllCosmetics
    case riseToTop
    case anyHomeSeat
    case unlimitedAwayPoints

    /// The StoreKit/App Store Connect product identifier this kind maps to.
    /// Must match a non-consumable In-App Purchase configured in App Store
    /// Connect (or a local `.storekit` testing configuration) with this
    /// exact identifier before a purchase can actually complete.
    public var productID: String {
        "com.cormacbrannigan03.UltrasEuropa.store.\(rawValue)"
    }

    public static func forProductID(_ productID: String) -> StoreProductKind? {
        allCases.first { $0.productID == productID }
    }
}
