import SwiftUI

/// A recovery badge (Recovery → Badges).
struct Badge: Identifiable {
    let id = UUID()
    let title: String
    let requirement: String
    enum State { case claimable, locked }
    let state: State
}

/// A level tier (Recovery → Levels).
struct Level: Identifiable {
    let id = UUID()
    let rank: Int
    let name: String
    let gemCost: Int?          // nil ⇒ current level ("You are here")
    let isCurrent: Bool
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

/// A subscription plan row.
struct Plan: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String
    let price: String
    let isPopular: Bool
}
