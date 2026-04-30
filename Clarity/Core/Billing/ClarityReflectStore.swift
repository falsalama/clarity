import Foundation
import Combine
import StoreKit

@MainActor
final class ClarityReflectStore: ObservableObject {
    private enum Keys {
        static let reflectAccess = "clarity.reflect.access.enabled"
        static let reflectProductID = "clarity.reflect.product.id"
        static let supportPurchased = "clarity.support.purchased"
        static let legacySupporterAccess = "supporter.access.enabled"
#if DEBUG && CLARITY_REFLECT_DEBUG_OVERRIDE
        static let debugReflectOverride = "clarity.reflect.debug.override"
#endif
    }

    static let monthlyProductID = "clarity_reflect_monthly"
    static let annualProductID = "clarity_reflect_annual"
    static let supportProductID = "support_clarity"
    static let support100ProductID = "support_clarity_100"
    static let support500ProductID = "support_clarity_500"
    static let support1000ProductID = "support_clarity_1000"

    @Published private(set) var products: [Product] = []
    @Published private(set) var hasReflectAccess: Bool
    @Published private(set) var hasSupportedClarity: Bool
    @Published private(set) var purchasedSupportProductIDs: Set<String>
    @Published private(set) var currentReflectProductID: String?
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var isRefreshingEntitlements = false
    @Published private(set) var isPurchasing = false
    @Published private(set) var productLoadIssue: String?
    @Published var lastError: String?
#if DEBUG && CLARITY_REFLECT_DEBUG_OVERRIDE
    @Published private(set) var hasDebugReflectOverride: Bool
#endif

    private var updatesTask: Task<Void, Never>?
    private var actualReflectEntitlement: Bool

    private struct AppleEntitlementSyncRequest: Encodable {
        let signedTransactionInfo: String
    }

    init() {
        let defaults = UserDefaults.standard
        let storedReflect = defaults.bool(forKey: Keys.reflectAccess)
        let storedReflectProductID = Self.reflectProductIDs.contains(defaults.string(forKey: Keys.reflectProductID) ?? "")
            ? defaults.string(forKey: Keys.reflectProductID)
            : nil
        let storedSupport = defaults.bool(forKey: Keys.supportPurchased)
        self.hasSupportedClarity = storedSupport
        self.purchasedSupportProductIDs = []
#if DEBUG && CLARITY_REFLECT_DEBUG_OVERRIDE
        let debugOverride = defaults.bool(forKey: Keys.debugReflectOverride)
        self.hasDebugReflectOverride = debugOverride
        self.hasReflectAccess = storedReflect || storedSupport || debugOverride
        self.actualReflectEntitlement = storedReflect
#else
        self.hasReflectAccess = storedReflect || storedSupport
        self.actualReflectEntitlement = storedReflect
#endif
        self.currentReflectProductID = storedReflect ? storedReflectProductID : nil
        self.updatesTask = Task { [weak self] in
            await self?.listenForTransactions()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    var reflectProducts: [Product] {
        orderProducts(matching: Self.reflectProductIDs)
    }

    static var reflectProductIDs: [String] {
        [
            Self.monthlyProductID,
            Self.annualProductID
        ]
    }

    static var allProductIDs: [String] {
        Self.reflectProductIDs + [
            Self.supportProductID,
            Self.support100ProductID,
            Self.support500ProductID,
            Self.support1000ProductID
        ]
    }

    static var supportProductIDs: [String] {
        [
            Self.supportProductID,
            Self.support100ProductID,
            Self.support500ProductID,
            Self.support1000ProductID
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

#if DEBUG && CLARITY_REFLECT_DEBUG_OVERRIDE
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

    func reloadProducts() async {
        await requestProducts()
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

                let synced = await syncServerEntitlement(
                    signedTransactionInfo: verification.jwsRepresentation
                )
                if !synced {
                    lastError = "Purchase completed, but cloud access could not be synced. Try Restore Purchases."
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
        productLoadIssue = nil
        defer { isLoadingProducts = false }

        do {
            let loaded = try await Product.products(for: Self.allProductIDs)
            products = orderProducts(loaded)

            if products.isEmpty {
                productLoadIssue = "Plans could not be loaded. Check the connection and try again."
            }
#if DEBUG
            if !products.isEmpty {
                let loadedIDs = Set(loaded.map(\.id))
                let missing = Self.allProductIDs.filter { !loadedIDs.contains($0) }
                if !missing.isEmpty {
                    productLoadIssue = "Loaded \(loaded.count) of \(Self.allProductIDs.count) StoreKit products. Missing: \(missing.joined(separator: ", "))."
                }
            }
#endif
        } catch {
            productLoadIssue = "Plans could not be loaded. Check the connection and try again."
#if DEBUG
            productLoadIssue = "\(productLoadIssue ?? "") \(error.localizedDescription)"
#endif
        }
    }

    private func refreshEntitlements() async {
        isRefreshingEntitlements = true
        defer { isRefreshingEntitlements = false }

        var hasReflect = false
        var hasSupport = hasSupportedClarity
        var activeReflectProductID: String?
        var supportIDs: Set<String> = []
        var serverSyncTransactions: [String] = []

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            switch transaction.productID {
            case let productID where Self.reflectProductIDs.contains(productID):
                hasReflect = true
                activeReflectProductID = transaction.productID
                serverSyncTransactions.append(result.jwsRepresentation)
            case let productID where Self.supportProductIDs.contains(productID):
                hasSupport = true
                supportIDs.insert(productID)
                serverSyncTransactions.append(result.jwsRepresentation)
            default:
                break
            }
        }

        currentReflectProductID = activeReflectProductID
        persistCurrentReflectProductID()
        purchasedSupportProductIDs = supportIDs
        applyReflectAccess(hasReflect)
        applySupportPurchased(hasSupport)

        for signedTransactionInfo in serverSyncTransactions {
            _ = await syncServerEntitlement(signedTransactionInfo: signedTransactionInfo)
        }
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            guard case .verified(let transaction) = result else { continue }

            if Self.supportProductIDs.contains(transaction.productID) {
                applySupportPurchased(true)
            }

            if Self.reflectProductIDs.contains(transaction.productID) ||
                Self.supportProductIDs.contains(transaction.productID) {
                _ = await syncServerEntitlement(
                    signedTransactionInfo: result.jwsRepresentation
                )
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
            Self.support1000ProductID
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
#if DEBUG && CLARITY_REFLECT_DEBUG_OVERRIDE
        let effective = base || hasDebugReflectOverride
#else
        let effective = base
#endif
        hasReflectAccess = effective
        UserDefaults.standard.set(actualReflectEntitlement, forKey: Keys.reflectAccess)
        UserDefaults.standard.set(base, forKey: Keys.legacySupporterAccess)
    }

    private func persistCurrentReflectProductID() {
        if let currentReflectProductID {
            UserDefaults.standard.set(currentReflectProductID, forKey: Keys.reflectProductID)
        } else {
            UserDefaults.standard.removeObject(forKey: Keys.reflectProductID)
        }
    }

    private func syncServerEntitlement(signedTransactionInfo: String) async -> Bool {
        guard case .available(let cfg) = CloudTapConfig.availability() else {
            return false
        }
        guard let accessToken = AppServices.supabaseAccessToken, !accessToken.isEmpty else {
            return false
        }

        let url = cloudFunctionURL(base: cfg.baseURL, endpoint: "verify-apple-entitlement")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.timeoutInterval = 30
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue(cfg.supabaseAnonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        do {
            req.httpBody = try JSONEncoder().encode(
                AppleEntitlementSyncRequest(
                    signedTransactionInfo: signedTransactionInfo
                )
            )

            let (_, response) = try await URLSession.shared.data(for: req)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            return (200..<300).contains(statusCode)
        } catch {
            return false
        }
    }

    private func cloudFunctionURL(base: URL, endpoint: String) -> URL {
        if base.lastPathComponent.hasPrefix("cloudtap-") {
            return base.deletingLastPathComponent().appendingPathComponent(endpoint)
        }
        return base.appendingPathComponent(endpoint)
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
