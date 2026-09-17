import Foundation

/// One item in the real-money store catalog (see `store_products.json`).
/// `priceDisplay` is a fallback shown before StoreKit's live, localized
/// price has loaded (or if it never does, e.g. in a preview with no
/// App Store Connect / StoreKit configuration attached) — the App layer
/// prefers the live `Product.displayPrice` whenever it's available.
public struct StoreProduct: Codable, Identifiable, Hashable, Sendable {
    public let kind: StoreProductKind
    public let name: String
    public let itemDescription: String
    public let priceDisplay: String

    public var id: String { kind.productID }

    public init(kind: StoreProductKind, name: String, itemDescription: String, priceDisplay: String) {
        self.kind = kind
        self.name = name
        self.itemDescription = itemDescription
        self.priceDisplay = priceDisplay
    }

    enum CodingKeys: String, CodingKey {
        case kind, name, priceDisplay
        case itemDescription = "description"
    }
}
