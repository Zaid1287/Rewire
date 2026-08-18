import SwiftUI

/// A recovery badge (Recovery → Badges).
struct Badge: Identifiable {
    let id = UUID()
    let title: String
    let requirement: String
    enum State { case claimable, locked }
    let state: State
}

/// A level tier (Recovery → Levels). Earned from real clean days, not bought.
struct Level: Identifiable {
    let id = UUID()
    let rank: Int
    let name: String
    let dayThreshold: Int      // clean days required to reach this level
}

/// A feature-hub row (Quit Porn tab, Recovery "make streaks easier").
struct FeatureItem: Identifiable {
    let id = UUID()
    let symbol: String
    let title: String
    let subtitle: String
    var badge: FeatureBadge? = nil
    var showsChevron: Bool = true
    var warning: Bool = false   // red exclamation dot after title
}

enum FeatureBadge {
    case popular
    case count(Int)
    /// Coming-soon row: no destination yet — rendered dimmed with a "Soon"
    /// capsule so it never reads as a working control.
    case soon
}

/// A single day in the 21-day Personal Plan checklist.
struct PlanDay: Identifiable {
    let day: Int
    let title: String
    let detail: String
    var id: Int { day }
}

/// A display-ready paywall row, built from a real StoreKit `Product` by
/// `Purchases.orderedPlans(from:)`. Every string here is already localized by
/// the App Store — nothing about a price is hardcoded.
struct Plan: Identifiable, Equatable {
    /// The StoreKit product ID — also the stable identity, so two rows built
    /// from the same product compare equal.
    let id: String
    let name: String        // "Monthly" / "Yearly" / "Lifetime"
    let subtitle: String    // "billed monthly" / "$2.49 a month, billed yearly"
    let price: String       // Product.displayPrice, in the storefront's currency
    let cadence: String     // "/mo" / "/yr" / "once"
    /// Price → renewal period, shown next to the CTA on every paywall.
    let disclosure: String
    let isPopular: Bool
}
