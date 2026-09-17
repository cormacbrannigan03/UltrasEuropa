import StoreKit
import Observation
import UltrasEuropaCore

/// Thin wrapper around StoreKit 2 for the real-money store. This is the
/// only place in the app that talks to StoreKit directly — `StoreView`
/// only ever sees `Product` values and calls `purchase`.
///
/// For a purchase to actually complete, the product identifiers returned
/// by `StoreProductKind.productID` must exist either as non-consumable
/// In-App Purchases configured in App Store Connect, or as products in a
/// local StoreKit Configuration file (see `App/StoreKit/Configuration.storekit`,
/// wired into the `UltrasEuropa` scheme's run configuration in
/// `project.yml`) for testing in the simulator without any App Store
/// Connect account. Neither of those can be created or verified from a
/// sandbox without Xcode, so this class is real, working StoreKit 2 code
/// that has not itself been run.
@Observable
final class PurchaseManager {
    private(set) var products: [Product] = []
    private(set) var purchasingProductID: String?
    private(set) var lastError: String?

    private let onVerifiedPurchase: (StoreProductKind) -> Void
    private var transactionListenerTask: Task<Void, Never>?

    init(onVerifiedPurchase: @escaping (StoreProductKind) -> Void) {
        self.onVerifiedPurchase = onVerifiedPurchase
        transactionListenerTask = Task { [weak self] in
            await self?.observeTransactionUpdates()
        }
    }

    deinit {
        transactionListenerTask?.cancel()
    }

    /// Fetches the live `Product` list (price, display name, description)
    /// for every id in `ids`. Safe to call more than once — a fresh load
    /// replaces the previous list.
    func loadProducts(ids: [String]) async {
        do {
            products = try await Product.products(for: ids)
            if products.isEmpty {
                lastError = "No store products found. Attach a StoreKit Configuration file (for testing) or configure these products in App Store Connect."
            } else {
                lastError = nil
            }
        } catch {
            lastError = "Couldn't load store products: \(error.localizedDescription)"
        }
    }

    /// Starts the purchase sheet for `product` and, once StoreKit reports a
    /// verified transaction, grants the entitlement via `onVerifiedPurchase`
    /// and finishes the transaction. Cancellation and pending states (e.g.
    /// Ask to Buy) are not errors — they're left for `Transaction.updates`
    /// to resolve later if the purchase eventually clears.
    func purchase(_ product: Product, kind: StoreProductKind) async {
        purchasingProductID = product.id
        defer { purchasingProductID = nil }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try verified(verification)
                onVerifiedPurchase(kind)
                await transaction.finish()
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            lastError = "Purchase failed: \(error.localizedDescription)"
        }
    }

    /// Restores entitlements for purchases already made on this Apple ID
    /// (a fresh install, a new device) without going through the buy flow
    /// again — StoreKit re-delivers them through `Transaction.currentEntitlements`.
    func restorePurchases() async {
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? verified(result),
                  let kind = StoreProductKind.forProductID(transaction.productID)
            else { continue }
            onVerifiedPurchase(kind)
        }
    }

    /// Long-running listener for transactions that complete outside the
    /// purchase call above (Ask to Buy approvals, purchases made on
    /// another device, StoreKit's own retry of an interrupted purchase).
    private func observeTransactionUpdates() async {
        for await result in Transaction.updates {
            guard let transaction = try? verified(result) else { continue }
            if let kind = StoreProductKind.forProductID(transaction.productID) {
                onVerifiedPurchase(kind)
            }
            await transaction.finish()
        }
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw PurchaseError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    private enum PurchaseError: Error {
        case failedVerification
    }
}
