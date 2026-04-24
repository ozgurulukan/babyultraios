//
//  SubscriptionManager.swift
//  Bubsie
//
//  Created by Ozgur Ulukan on 18/07/24.
//

import StoreKit

class SubscriptionsManager: NSObject, ObservableObject {
    // NOTE: Ensure these IDs match the plans shown in PremiumView.
    // The new paywall design shows Yearly and Weekly plans.
    let productIDs: [String] = ["com.monthly", "com.yearly"]
    var purchasedProductIDs: Set<String> = []

    @Published var products: [Product] = []
    
    private var entitlementManager: EntitlementManager? = nil
    private var updates: Task<Void, Never>? = nil
    
    init(entitlementManager: EntitlementManager) {
        self.entitlementManager = entitlementManager
        super.init()
        self.updates = observeTransactionUpdates()
        SKPaymentQueue.default().add(self)
    }
    
    deinit {
        updates?.cancel()
    }
    
    func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) { [unowned self] in
            for await _ in Transaction.updates {
                await self.updatePurchasedProducts()
            }
        }
    }
}

// MARK: StoreKit2 API
extension SubscriptionsManager {
    func loadProducts() async {
        do {
            let fetched = try await Product.products(for: productIDs)
                .sorted(by: { $0.price > $1.price })
            await MainActor.run {
                self.products = fetched
            }
        } catch {
            print("Failed to fetch products!")
        }
    }
    
    func buyProduct(_ product: Product) async {
        do {
            let result = try await product.purchase()
            
            switch result {
            case let .success(.verified(transaction)):
                // Successful purhcase
                await transaction.finish()
                await self.updatePurchasedProducts()
            case let .success(.unverified(_, error)):
                // Successful purchase but transaction/receipt can't be verified
                // Could be a jailbroken phone
                print("Unverified purchase. Might be jailbroken. Error: \(error)")
                break
            case .pending:
                // Transaction waiting on SCA (Strong Customer Authentication) or
                // approval from Ask to Buy
                break
            case .userCancelled:
                print("User cancelled!")
                break
            @unknown default:
                print("Failed to purchase the product!")
                break
            }
        } catch {
            print("Failed to purchase the product!")
        }
    }
    
    func updatePurchasedProducts() async {
        var purchased = Set<String>()
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.revocationDate == nil {
                purchased.insert(transaction.productID)
            }
        }
        let purchasedIDs = purchased
        let hasActiveSubscription = !purchasedIDs.isEmpty
        await MainActor.run {
            self.purchasedProductIDs = purchasedIDs
            self.entitlementManager?.hasPro = hasActiveSubscription
        }

        let shouldSyncPro = await MainActor.run {
            hasActiveSubscription && (AuthManager.shared.currentUser?.isPro != true)
        }
        if shouldSyncPro {
            await syncProStatusToBackend()
        }
    }
    
    func restorePurchases() async {
        do {
            try await AppStore.sync()
        } catch {
            print(error)
        }
    }

    private func syncProStatusToBackend() async {
        do {
            try await BubsieAPI.shared.activatePro()
            await AuthManager.shared.fetchProfile()
        } catch {
            print("Failed to sync pro status with backend: \(error)")
        }
    }
}

extension SubscriptionsManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        return true
    }
}
