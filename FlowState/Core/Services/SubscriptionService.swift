import Foundation
import StoreKit

@Observable
final class SubscriptionService {

    // MARK: - Product IDs
    enum ProductID {
        static let monthly = "com.flowstate.app.premium.monthly"
        static let annual = "com.flowstate.app.premium.annual"
        static let allIDs = [monthly, annual]
    }

    // MARK: - State
    private(set) var isPremium: Bool = true // DEBUG: default premium for development
    private(set) var products: [Product] = []
    private(set) var purchaseError: String?
    private(set) var isLoading: Bool = false

    private var transactionUpdateTask: Task<Void, Never>?

    // MARK: - Init
    init() {
        transactionUpdateTask = listenForTransactions()
        Task {
            await checkEntitlements()
            await loadProducts()
        }
    }

    deinit {
        transactionUpdateTask?.cancel()
    }

    // MARK: - Load Products
    func loadProducts() async {
        do {
            let fetchedProducts = try await Product.products(for: ProductID.allIDs)
            await MainActor.run {
                // Sort: annual first
                self.products = fetchedProducts.sorted { a, b in
                    a.id == ProductID.annual
                }
            }
        } catch {
            print("SubscriptionService: Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase
    func purchase(_ product: Product) async -> Bool {
        await MainActor.run { isLoading = true; purchaseError = nil }

        do {
            let result = try await product.purchase()
            await MainActor.run { isLoading = false }

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await checkEntitlements()
                return true
            case .userCancelled:
                return false
            case .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            await MainActor.run {
                purchaseError = error.localizedDescription
                isLoading = false
            }
            return false
        }
    }

    // MARK: - Restore
    func restorePurchases() async {
        await MainActor.run { isLoading = true }
        do {
            try await AppStore.sync()
            await checkEntitlements()
        } catch {
            await MainActor.run { purchaseError = error.localizedDescription }
        }
        await MainActor.run { isLoading = false }
    }

    // MARK: - Check Entitlements
    func checkEntitlements() async {
        var hasPremium = false
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if ProductID.allIDs.contains(transaction.productID) {
                    if transaction.revocationDate == nil {
                        hasPremium = true
                    }
                }
            } catch {
                print("SubscriptionService: Transaction verification failed")
            }
        }
        await MainActor.run {
            #if !DEBUG
            isPremium = hasPremium
            #endif
        }
    }

    // MARK: - Listen for Transactions
    private func listenForTransactions() -> Task<Void, Never> {
        Task(priority: .background) {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await transaction.finish()
                    await self.checkEntitlements()
                } catch {
                    print("SubscriptionService: Transaction update verification failed")
                }
            }
        }
    }

    // MARK: - Verify Transaction
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let transaction):
            return transaction
        }
    }

    // MARK: - Formatted Price
    func formattedPrice(for product: Product) -> String {
        product.displayPrice
    }

    func monthlyEquivalent(for product: Product) -> String? {
        guard product.id == ProductID.annual,
              let subscription = product.subscription,
              let introOffer = subscription.introductoryOffer else { return nil }
        return nil // Simplified for now
    }
}

// MARK: - Store Error
enum StoreError: Error {
    case failedVerification
    case productNotFound
}

// MARK: - Mock Premium (Simulator)
#if DEBUG
extension SubscriptionService {
    func debugSetPremium(_ value: Bool) {
        isPremium = value
    }
}
#endif
