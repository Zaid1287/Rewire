import Foundation
import StoreKit

/// The only thing in the app that talks to StoreKit, and the only writer of
/// `GemStore.isPremium`. Entitlement — not a local flag we flip ourselves — is
/// the source of truth for Premium, so a cancelled subscription actually ends
/// and "Restore Purchase" can only restore something real.
///
/// Premium is **free core, paid depth** (see PAYWALL-CLUSTER.md): every crisis,
/// streak, blocker and check-in tool is free forever; these products buy depth.
/// **No introductory offer / free trial** — the billing-trap complaint is the
/// loudest in the competitor review set, so monthly *is* the trial.
@MainActor @Observable
final class Purchases {

    enum ProductID {
        static let monthly  = "com.manimacha.rewire.premium.monthly"
        static let yearly   = "com.manimacha.rewire.premium.yearly"
        static let lifetime = "com.manimacha.rewire.lifetime"
        /// Cheapest → best. Order drives both the paywall rows and which
        /// entitlement wins when a user somehow holds more than one.
        static let all = [monthly, yearly, lifetime]
    }

    enum LoadState: Equatable { case loading, loaded, failed }

    enum PurchaseOutcome: Equatable {
        case success
        /// Ask-to-buy / SCA — the App Store will tell us later via `Transaction.updates`.
        case pending
        case cancelled
        case failed(String)
    }

    // MARK: State the paywalls read

    private(set) var plans: [Plan] = []
    private(set) var loadState: LoadState = .loading
    private(set) var isPurchasing = false
    private(set) var isEntitled = false
    private(set) var entitledProductID: String?

    /// Set by RewireApp so the entitlement lands on GemStore, which is what the
    /// rest of the app reads. Called on every refresh, in both directions.
    var onEntitlement: ((Bool, String?) -> Void)?

    private var products: [String: Product] = [:]
    /// Held for the app's lifetime — `Purchases` is created once by RewireApp
    /// and never torn down, so there is nothing to cancel it from.
    private var updates: Task<Void, Never>?

    init() {
        // Renewals, revocations, Ask-to-Buy approvals and purchases made on
        // another device all arrive here rather than through `purchase()`.
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result { await transaction.finish() }
                await self?.refreshEntitlement()
            }
        }
    }

    // MARK: Loading

    /// Fetch the products, then reconcile the entitlement. Safe to call again.
    func load() async {
        if plans.isEmpty { loadState = .loading }
        do {
            let fetched = try await Product.products(for: ProductID.all)
            products = Dictionary(fetched.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
            plans = Self.orderedPlans(from: products)
            loadState = plans.isEmpty ? .failed : .loaded
        } catch {
            loadState = plans.isEmpty ? .failed : .loaded
        }
        await refreshEntitlement()
    }

    // MARK: Buying

    func purchase(_ plan: Plan) async -> PurchaseOutcome {
        guard let product = products[plan.id] else {
            return .failed("That plan isn't available right now.")
        }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    // Unverified means the App Store's signature didn't check
                    // out. Never grant on that.
                    return .failed("We couldn't verify that purchase with the App Store.")
                }
                await transaction.finish()
                await refreshEntitlement()
                return .success
            case .pending:
                return .pending
            case .userCancelled:
                return .cancelled
            @unknown default:
                return .failed("Something unexpected happened. Nothing was charged.")
            }
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    /// `true` only if a real receipt turned up. `AppStore.sync()` re-prompts for
    /// the Apple ID password, so this is only ever called from the explicit
    /// Restore Purchase button.
    func restore() async -> Bool {
        try? await AppStore.sync()
        await refreshEntitlement()
        return isEntitled
    }

    // MARK: Entitlement

    /// Re-reads the on-device entitlements (works offline) and pushes the answer
    /// to GemStore. Can and does revoke: an expired or refunded subscription
    /// turns Premium back off here.
    func refreshEntitlement() async {
        var owned: [String] = []
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.revocationDate == nil else { continue }
            if let expiry = transaction.expirationDate, expiry <= Date() { continue }
            owned.append(transaction.productID)
        }
        let best = Self.bestEntitlement(among: owned)
        isEntitled = best != nil
        entitledProductID = best
        onEntitlement?(best != nil, best)
    }

    // MARK: Pure helpers

    /// The plan a user holding `ids` should be treated as having: the furthest
    /// along `ProductID.all`, so lifetime beats yearly beats monthly and an
    /// unknown/legacy id never wins.
    static func bestEntitlement(among ids: [String]) -> String? {
        ids.filter { ProductID.all.contains($0) }
           .max { (ProductID.all.firstIndex(of: $0) ?? -1) < (ProductID.all.firstIndex(of: $1) ?? -1) }
    }

    /// Products → display-ready rows in a fixed cheapest-first order, so the
    /// paywall never depends on the order the App Store happened to reply in.
    static func orderedPlans(from products: [String: Product]) -> [Plan] {
        ProductID.all.compactMap { id in
            guard let product = products[id] else { return nil }
            return Plan(id: id,
                        name: name(for: id),
                        subtitle: subtitle(for: product),
                        price: product.displayPrice,
                        cadence: cadence(for: id),
                        disclosure: disclosure(for: id, price: product.displayPrice),
                        isPopular: id == ProductID.yearly)
        }
    }

    private static func name(for id: String) -> String {
        switch id {
        case ProductID.monthly: "Monthly"
        case ProductID.yearly:  "Yearly"
        default:                "Lifetime"
        }
    }

    private static func cadence(for id: String) -> String {
        switch id {
        case ProductID.monthly: "/mo"
        case ProductID.yearly:  "/yr"
        default:                "once"
        }
    }

    /// Price → renewal period, next to the CTA, in the same words on every
    /// paywall. This is the disclosure the free-trial-trap reviews are about.
    private static func disclosure(for id: String, price: String) -> String {
        switch id {
        case ProductID.monthly: "\(price) per month, renews until you cancel."
        case ProductID.yearly:  "\(price) per year, renews until you cancel."
        default:                "\(price) once. Not a subscription — nothing renews."
        }
    }

    private static func subtitle(for product: Product) -> String {
        switch product.id {
        case ProductID.monthly: "billed monthly"
        case ProductID.yearly:  "\(perMonth(of: product)) a month, billed yearly"
        default:                "pay once, keep it forever"
        }
    }

    /// Yearly price ÷ 12 in the storefront's own currency — never a hardcoded
    /// "only ₹58.25/month" that is wrong everywhere outside one country.
    private static func perMonth(of product: Product) -> String {
        (product.price / 12).formatted(product.priceFormatStyle)
    }

    #if DEBUG
    /// No test target; the entitlement pick is money-critical, so it checks
    /// itself on debug launch (same pattern as `StreakStore.selfCheck`).
    static func selfCheck() {
        precondition(bestEntitlement(among: []) == nil)
        precondition(bestEntitlement(among: ["not.a.product"]) == nil,
                     "an unknown product id must never grant premium")
        precondition(bestEntitlement(among: [ProductID.monthly]) == ProductID.monthly)
        // Holding several: the best one wins, whatever order they arrive in.
        precondition(bestEntitlement(among: [ProductID.monthly, ProductID.lifetime, ProductID.yearly])
                     == ProductID.lifetime)
        precondition(bestEntitlement(among: [ProductID.yearly, ProductID.monthly]) == ProductID.yearly)
        precondition(bestEntitlement(among: ["legacy.mock", ProductID.monthly]) == ProductID.monthly)
        print("Purchases.selfCheck passed")
    }
    #endif
}
