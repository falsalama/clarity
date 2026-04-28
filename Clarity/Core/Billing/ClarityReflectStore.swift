import Foundation
import Combine
import StoreKit

@MainActor
final class ClarityReflectStore: ObservableObject {
    private enum Keys {
        static let reflectAccess = "clarity.reflect.access.enabled"
        static let supportPurchased = "clarity.support.purchased"
        static let legacySupporterAccess = "supporter.access.enabled"
#if DEBUG
        static let debugReflectOverride = "clarity.reflect.debug.override"
#endif
    }

    static let monthlyProductID = "clarity_reflect_monthly"
    static let annualProductID = "clarity_reflect_annual"
    static let supportProductID = "support_clarity"
    static let support100ProductID = "support_clarity_100"
    static let support500ProductID = "support_clarity_500"
    static let support1000ProductID = "support_clarity_1000"
    static let support10000ProductID = "support_clarity_10000"

    @Published private(set) var products: [Product] = []
    @Published private(set) var hasReflectAccess: Bool
    @Published private(set) var hasSupportedClarity: Bool
    @Published private(set) var purchasedSupportProductIDs: Set<String>
    @Published private(set) var currentReflectProductID: String?
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var isRefreshingEntitlements = false
    @Published private(set) var isPurchasing = false
    @Published var lastError: String?
#if DEBUG
    @Published private(set) var hasDebugReflectOverride: Bool
#endif

    private var updatesTask: Task<Void, Never>?
    private var actualReflectEntitlement: Bool

    init() {
        let defaults = UserDefaults.standard
        let storedReflect = defaults.bool(forKey: Keys.reflectAccess)
        let storedSupport = defaults.bool(forKey: Keys.supportPurchased)
        self.hasSupportedClarity = storedSupport
        self.purchasedSupportProductIDs = []
#if DEBUG
        let debugOverride = defaults.bool(forKey: Keys.debugReflectOverride)
        self.hasDebugReflectOverride = debugOverride
        self.hasReflectAccess = storedReflect || storedSupport || debugOverride
#else
        self.hasReflectAccess = storedReflect || storedSupport
#endif
        self.actualReflectEntitlement = storedReflect
        self.currentReflectProductID = nil
        self.updatesTask = Task { [weak self] in
            await self?.listenForTransactions()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    var reflectProducts: [Product] {
        orderProducts(matching: [Self.monthlyProductID, Self.annualProductID])
    }

    static var supportProductIDs: [String] {
        [
            Self.supportProductID,
            Self.support100ProductID,
            Self.support500ProductID,
            Self.support1000ProductID,
            Self.support10000ProductID
        ]
    }

    var supportProducts: [Product] {
        orderProducts(matching: Self.supportProductIDs)
    }

    var supportProduct: Product? {
        products.first(where: { $0.id == Self.supportProductID })
    }

    var currentReflectProduct: Product? {
        guard let currentReflectProductID else { return nil }
        return products.first(where: { $0.id == currentReflectProductID })
    }

    var isSupportOnlyActive: Bool {
        currentReflectProductID == nil && hasSupportedClarity
    }

    var hasPaidTier: Bool {
        currentReflectProductID != nil || hasSupportedClarity
    }

    var accountTierTitle: String {
        if isSupportOnlyActive {
            return "Support Clarity"
        }
        switch currentReflectProductID {
        case Self.monthlyProductID:
            return "Clarity Reflect Monthly"
        case Self.annualProductID:
            return "Clarity Reflect Annual"
        default:
            return "Free"
        }
    }

#if DEBUG
    func setDebugReflectOverride(_ enabled: Bool) {
        hasDebugReflectOverride = enabled
        UserDefaults.standard.set(enabled, forKey: Keys.debugReflectOverride)
        updateEffectiveAccess()
    }
#endif

    func prepare() async {
        await requestProducts()
        await refreshEntitlements()
    }

    func purchase(_ product: Product) async {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try verify(verification)

                if Self.supportProductIDs.contains(transaction.productID) {
                    applySupportPurchased(true)
                }

                await transaction.finish()
                await refreshEntitlements()

            case .pending:
                lastError = "Purchase is pending approval."

            case .userCancelled:
                break

            @unknown default:
                lastError = "Purchase could not be completed."
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    func restorePurchases() async {
        isRefreshingEntitlements = true
        defer { isRefreshingEntitlements = false }

        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func requestProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        do {
            let loaded = try await Product.products(for: [
                Self.monthlyProductID,
                Self.annualProductID,
                Self.supportProductID,
                Self.support100ProductID,
                Self.support500ProductID,
                Self.support1000ProductID,
                Self.support10000ProductID
            ])
            products = orderProducts(loaded)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func refreshEntitlements() async {
        isRefreshingEntitlements = true
        defer { isRefreshingEntitlements = false }

        var hasReflect = false
        var hasSupport = hasSupportedClarity
        var activeReflectProductID: String?
        var supportIDs: Set<String> = []

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            switch transaction.productID {
            case Self.monthlyProductID, Self.annualProductID:
                hasReflect = true
                activeReflectProductID = transaction.productID
            case let productID where Self.supportProductIDs.contains(productID):
                hasSupport = true
                supportIDs.insert(productID)
            default:
                break
            }
        }

        purchasedSupportProductIDs = supportIDs
        applyReflectAccess(hasReflect)
        currentReflectProductID = activeReflectProductID
        applySupportPurchased(hasSupport)
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            guard case .verified(let transaction) = result else { continue }

            if Self.supportProductIDs.contains(transaction.productID) {
                applySupportPurchased(true)
            }

            await transaction.finish()
            await refreshEntitlements()
        }
    }

    private func orderProducts(_ loaded: [Product]) -> [Product] {
        let ids = [
            Self.monthlyProductID,
            Self.annualProductID,
            Self.supportProductID,
            Self.support100ProductID,
            Self.support500ProductID,
            Self.support1000ProductID,
            Self.support10000ProductID
        ]
        let byID = Dictionary(uniqueKeysWithValues: loaded.map { ($0.id, $0) })
        return ids.compactMap { byID[$0] }
    }

    private func orderProducts(matching ids: [String]) -> [Product] {
        let byID = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
        return ids.compactMap { byID[$0] }
    }

    private func applyReflectAccess(_ value: Bool) {
        actualReflectEntitlement = value
        updateEffectiveAccess()
    }

    private func applySupportPurchased(_ value: Bool) {
        hasSupportedClarity = value
        UserDefaults.standard.set(value, forKey: Keys.supportPurchased)
        updateEffectiveAccess()
    }

    private func updateEffectiveAccess() {
        let base = actualReflectEntitlement || hasSupportedClarity
#if DEBUG
        let effective = base || hasDebugReflectOverride
#else
        let effective = base
#endif
        hasReflectAccess = effective
        UserDefaults.standard.set(effective, forKey: Keys.reflectAccess)
        UserDefaults.standard.set(effective, forKey: Keys.legacySupporterAccess)
    }

    private func verify<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw StoreError.verificationFailed
        }
    }
}

private enum StoreError: LocalizedError {
    case verificationFailed

    var errorDescription: String? {
        switch self {
        case .verificationFailed:
            return "Purchase verification failed."
        }
    }
}
