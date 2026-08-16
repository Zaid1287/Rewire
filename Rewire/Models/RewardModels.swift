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

/// A subscription plan row.
struct Plan: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String
    let price: String
    let isPopular: Bool
}
