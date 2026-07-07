import SwiftUI

/// Gamification currency shown in the top-right pill across the app
/// (gems + coins). Onboarding awards gems as the quiz progresses (100 → 750).
/// Also holds the small pieces of recovery progress (claimed badges, liked
/// superpowers, current level) — one gamification store rather than three.
@Observable
final class GemStore {
    var gems: Int = 750 { didSet { persist?() } }     // ends onboarding at 750 per the Home header
    var coins: Int = 0 { didSet { persist?() } }
    /// Whether the premium subscription is unlocked.
    private(set) var isPremium: Bool = false { didSet { persist?() } }

    /// Recovery progress. Stable keys: badge `title`, superpower `title`.
    private(set) var claimedBadges: Set<String> = [] { didSet { persist?() } }
    private(set) var likedSuperpowers: Set<String> = [] { didSet { persist?() } }
    /// Current level rank (see SampleData.levels — stable Int, never regenerated).
    private(set) var currentLevel: Int = 1 { didSet { persist?() } }

    /// One-time special-offer deadline — set on first Home visit, never reset.
    /// The Home banner shows while `Date() < offerDeadline`.
    private(set) var offerDeadline: Date? = nil { didSet { persist?() } }

    /// Saver injected by RewireApp so mutations flush to disk.
    var persist: (() -> Void)?

    // MARK: Gems

    func award(_ amount: Int) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            gems += amount
        }
    }

    /// Spend gems. Returns false (no-op) when the balance can't cover it.
    @discardableResult
    func spend(_ amount: Int) -> Bool {
        guard gems >= amount else { return false }
        gems -= amount
        return true
    }

    // MARK: Coins

    func awardCoins(_ amount: Int) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            coins += amount
        }
    }

    @discardableResult
    func spendCoins(_ amount: Int) -> Bool {
        guard coins >= amount else { return false }
        coins -= amount
        return true
    }

    // MARK: Premium

    func unlockPremium() { isPremium = true }

    /// Start the one-time special offer (6 minutes) if it never ran.
    func startOfferIfNeeded() {
        guard offerDeadline == nil else { return }
        offerDeadline = Date().addingTimeInterval(6 * 60)
    }

    // MARK: Recovery progress

    func claimBadge(_ key: String) { claimedBadges.insert(key) }

    func toggleLike(_ key: String) {
        if likedSuperpowers.contains(key) { likedSuperpowers.remove(key) }
        else { likedSuperpowers.insert(key) }
    }

    func advanceLevel() { currentLevel += 1 }

    // MARK: Persistence

    func restore(from s: AppSnapshot) {
        gems = s.gems
        coins = s.coins
        isPremium = s.isPremium
        claimedBadges = s.claimedBadges
        likedSuperpowers = s.likedSuperpowers
        currentLevel = s.currentLevel
        offerDeadline = s.offerDeadline
    }
}
