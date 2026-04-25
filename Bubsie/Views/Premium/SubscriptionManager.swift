//
//  SubscriptionManager.swift
//  Bubsie
//
//  Created by Ozgur Ulukan on 18/07/24.
//

import Foundation
import Combine
import RevenueCat

// MARK: - RevenueCat Delegate (NSObject required for PurchasesDelegate)
private class RevenueCatDelegate: NSObject, PurchasesDelegate {
    var onUpdate: ((CustomerInfo) -> Void)?

    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        onUpdate?(customerInfo)
    }
}

// MARK: - Subscriptions Manager
final class SubscriptionsManager: ObservableObject {
    @Published var packages: [Package] = []
    @Published var isLoading = false
    @Published var creditProducts: [StoreProduct] = []
    @Published var isLoadingCredits = false

    private var entitlementManager: EntitlementManager?
    private let rcDelegate = RevenueCatDelegate()

    init(entitlementManager: EntitlementManager) {
        self.entitlementManager = entitlementManager
        rcDelegate.onUpdate = { [weak self] info in
            guard let self = self else { return }
            Task { await self.handleCustomerInfo(info) }
        }
        Purchases.shared.delegate = rcDelegate
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let offerings = try await Purchases.shared.offerings()
            await MainActor.run {
                if let current = offerings.current {
                    // Sort yearly first, then weekly
                    self.packages = current.availablePackages.sorted { a, b in
                        let aYearly = a.storeProduct.subscriptionPeriod?.unit == .year
                        let bYearly = b.storeProduct.subscriptionPeriod?.unit == .year
                        if aYearly && !bYearly { return true }
                        if !aYearly && bYearly { return false }
                        return false
                    }
                } else {
                    self.packages = []
                }
            }
        } catch {
            print("Failed to fetch offerings: \(error)")
        }
    }

    func loadCreditProducts() async {
        isLoadingCredits = true
        defer { isLoadingCredits = false }
        let identifiers = [
            "com.fagore.bubsie.100credits",
            "com.fagore.bubsie.250credits",
            "com.fagore.bubsie.1000credits"
        ]
        let products = await Purchases.shared.products(identifiers)
        await MainActor.run {
            self.creditProducts = products
        }
    }

    func buyCreditProduct(_ product: StoreProduct) async throws -> CustomerInfo {
        let result = try await Purchases.shared.purchase(product: product)
        await handleCustomerInfo(result.customerInfo)
        return result.customerInfo
    }

    func buyProduct(_ package: Package) async throws -> CustomerInfo {
        let result = try await Purchases.shared.purchase(package: package)
        await handleCustomerInfo(result.customerInfo)
        return result.customerInfo
    }

    func restorePurchases() async {
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            await handleCustomerInfo(customerInfo)
        } catch {
            print("Restore failed: \(error)")
        }
    }

    func updatePurchasedProducts() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            await handleCustomerInfo(customerInfo)
        } catch {
            print("Failed to get customer info: \(error)")
        }
    }

    @MainActor
    private func handleCustomerInfo(_ customerInfo: CustomerInfo) async {
        let hasPro = customerInfo.entitlements[REVENUECAT_PRO_ENTITLEMENT]?.isActive == true
        self.entitlementManager?.hasPro = hasPro

        let shouldSyncPro = hasPro && (AuthManager.shared.currentUser?.isPro != true)
        if shouldSyncPro {
            await syncProStatusToBackend()
        }
    }

    private func syncProStatusToBackend() async {
        do {
            try await BubsieAPI.shared.syncPurchases()
            await AuthManager.shared.fetchProfile()
        } catch {
            print("Failed to sync purchases with backend: \(error)")
        }
    }
}
