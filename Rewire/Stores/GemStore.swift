import SwiftUI

/// Recovery progress and premium state (claimed badges, liked superpowers,
/// achievements, subscription) — no longer a currency store; levels are
/// earned from real clean time (see SampleData.level(forDays:)), not bought.
@Observable
final class GemStore {
    /// Whether the premium subscription is unlocked.
    private(set) var isPremium: Bool = false { didSet { persist?() } }

    /// Which plan was purchased ("1 month" / "1 year" / "Lifetime") — drives
    /// whether upgrade entry points still show. nil on pre-plan snapshots.
    private(set) var premiumPlan: String? = nil { didSet { persist?() } }

    /// Lifetime owners have nothing left to buy.
    var canUpgrade: Bool { !isPremium || premiumPlan != "Lifetime" }

    /// Recovery progress. Stable keys: badge `title`, superpower `title`.
    private(set) var claimedBadges: Set<String> = [] { didSet { persist?() } }
    private(set) var likedSuperpowers: Set<String> = [] { didSet { persist?() } }

    /// Misc one-off unlocks (e.g. "community") — stable string keys, checked
    /// with `contains`. Separate from badges/superpowers since not every
    /// achievement maps to a Recovery tile.
    private(set) var achievements: Set<String> = [] { didSet { persist?() } }

    /// Saver injected by RewireApp so mutations flush to disk.
    var persist: (() -> Void)?

    // MARK: Premium

    /// plan is nil when we can't know which plan was bought (Restore Purchase) —
    /// premium unlocks but the upgrade banner stays until a Lifetime purchase.
    func unlockPremium(plan: String? = nil) {
        isPremium = true
        if let plan { premiumPlan = plan }
    }

    // MARK: Recovery progress

    func claimBadge(_ key: String) { claimedBadges.insert(key) }

    func toggleLike(_ key: String) {
        if likedSuperpowers.contains(key) { likedSuperpowers.remove(key) }
        else { likedSuperpowers.insert(key) }
    }

    /// Record a one-off achievement. No-op if already recorded.
    func recordAchievement(_ key: String) { achievements.insert(key) }

    // MARK: Persistence

    func restore(from s: AppSnapshot) {
        isPremium = s.isPremium
        claimedBadges = s.claimedBadges
        likedSuperpowers = s.likedSuperpowers
        achievements = s.achievements ?? []
        premiumPlan = s.premiumPlan
    }
}
