import SwiftUI
import StoreKit
import UltrasEuropaCore

struct StoreView: View {
    @Environment(CharacterStore.self) private var characterStore
    @Environment(ContentStore.self) private var contentStore

    @State private var purchaseManager: PurchaseManager?

    var body: some View {
        List {
            Section {
                Text("Real-money purchases that fast-track your journey. Every one of these is a permanent shortcut, not a cosmetic-only extra — buy only what you're happy to skip earning.")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
            .listRowBackground(Theme.cardBackground)

            Section("Fast Track") {
                ForEach(contentStore.repository.storeProducts) { storeProduct in
                    StoreProductRow(
                        storeProduct: storeProduct,
                        liveProduct: purchaseManager?.products.first { $0.id == storeProduct.id },
                        isOwned: characterStore.hasPurchased(storeProduct.kind),
                        isPurchasing: purchaseManager?.purchasingProductID == storeProduct.id,
                        onBuy: { await buy(storeProduct) }
                    )
                }
            }
            .listRowBackground(Theme.cardBackground)

            if let error = purchaseManager?.lastError {
                Section {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .listRowBackground(Theme.cardBackground)
            }

            Section {
                Button("Restore Purchases") {
                    Task { await purchaseManager?.restorePurchases() }
                }
                .foregroundStyle(Theme.accent)
            }
            .listRowBackground(Theme.cardBackground)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Store")
        .task {
            let manager = PurchaseManager { kind in
                characterStore.grantStorePurchase(kind)
            }
            purchaseManager = manager
            await manager.loadProducts(ids: contentStore.repository.storeProducts.map(\.id))
        }
    }

    private func buy(_ storeProduct: StoreProduct) async {
        guard let manager = purchaseManager,
              let liveProduct = manager.products.first(where: { $0.id == storeProduct.id })
        else { return }
        await manager.purchase(liveProduct, kind: storeProduct.kind)
    }
}

private struct StoreProductRow: View {
    let storeProduct: StoreProduct
    let liveProduct: Product?
    let isOwned: Bool
    let isPurchasing: Bool
    let onBuy: () async -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(storeProduct.name).font(.headline)
                Text(storeProduct.itemDescription)
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
            Spacer()
            trailing
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var trailing: some View {
        if isOwned {
            Text("Owned")
                .font(.caption.bold())
                .foregroundStyle(Theme.accent)
        } else if isPurchasing {
            ProgressView()
        } else {
            Button(liveProduct?.displayPrice ?? storeProduct.priceDisplay) {
                Task { await onBuy() }
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)
        }
    }
}
