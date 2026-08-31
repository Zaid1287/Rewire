import SwiftUI

/// Recovery progress and premium state (claimed badges, achievements,
/// subscription) — no longer a currency store; levels are
/// earned from real clean time (see SampleData.level(forDays:)), not bought.
@Observable
final class GemStore {
    /// Whether Premium is unlocked. **`Purchases` is the only writer** — this is
    /// a cache of the StoreKit entitlement, persisted so the first frame after
    /// launch doesn't flash "free" before `Transaction.currentEntitlements`
    /// answers. It is corrected in both directions on every refresh, so a
    /// cancelled or refunded subscription really does end.
    private(set) var isPremium: Bool = false { didSet { persist?() } }

    /// The entitled StoreKit product ID — drives whether upgrade entry points
    /// still show. nil when not entitled. (Snapshots written before StoreKit
    /// hold a plan *title* here; the first entitlement refresh overwrites it.)
    private(set) var premiumPlan: String? = nil { didSet { persist?() } }

    /// Lifetime owners have nothing left to buy.
    var canUpgrade: Bool { !isPremium || premiumPlan != Purchases.ProductID.lifetime }

    /// Recovery progress. Stable key: badge `title`.
    private(set) var claimedBadges: Set<String> = [] { didSet { persist?() } }

    /// Misc one-off unlocks (e.g. "community") — stable string keys, checked
    /// with `contains`. Separate from badges since not every achievement maps
    /// to a Recovery tile.
    private(set) var achievements: Set<String> = [] { didSet { persist?() } }

    /// Saver injected by RewireApp so mutations flush to disk.
    var persist: (() -> Void)?

    // MARK: Premium

    /// The single entry point for premium state, called by `Purchases` after
    /// every entitlement read. Nothing else may grant premium — that hole is
    /// what made "Restore Purchase" a free premium button.
    func applyEntitlement(active: Bool, productID: String?) {
        isPremium = active
        premiumPlan = productID
    }

    // MARK: Recovery progress

    func claimBadge(_ key: String) { claimedBadges.insert(key) }

    /// Record a one-off achievement. No-op if already recorded.
    func recordAchievement(_ key: String) { achievements.insert(key) }

    // MARK: Persistence

    func restore(from s: AppSnapshot) {
        isPremium = s.isPremium
        claimedBadges = s.claimedBadges
        achievements = s.achievements ?? []
        premiumPlan = s.premiumPlan
    }
}
