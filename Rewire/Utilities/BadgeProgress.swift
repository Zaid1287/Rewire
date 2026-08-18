import Foundation

/// Whether a Recovery badge has actually been earned, based on real app state.
/// Keeps badges from being free-claimable — `BadgesView` and `MainTabView`
/// both gate the Claim button / unclaimed count through this.
enum BadgeProgress {
    /// Earned-but-unclaimed count across the full badge catalog — drives the
    /// Recovery tab badge and the My Collection bubble.
    static func unclaimedCount(appState: AppState, streak: StreakStore, gems: GemStore) -> Int {
        (SampleData.claimableBadges + SampleData.lockedBadges).filter {
            !gems.claimedBadges.contains($0.title)
                && isEarned($0, appState: appState, streak: streak, gems: gems)
        }.count
    }

    static func isEarned(_ badge: Badge, appState: AppState, streak: StreakStore, gems: GemStore) -> Bool {
        switch badge.title {
        case "Determined":              return true
        case "Daily Reporter":          return !streak.reports.isEmpty
        case "Goal Setter":             return gems.achievements.contains("setGoal")
        case "Panic Breaker":           return gems.achievements.contains("panic")
        case "Streak Guard":            return appState.reminderEnabled
        case "Breathing Champ":         return gems.achievements.contains("breathing")
        case "Challenger":              return streak.challengeJoined
        case "Motivation Master":       return !appState.motivations.isEmpty
        // Slip-log era (Phase 2): honesty is the badge, not a penalty toggle.
        case "Responsible":             return streak.events.contains { $0.type == .relapse }
        case "Pattern Finder":          return streak.events.filter { $0.type == .relapse }.count >= 3
        case "Loyal Member":            return !streak.events.isEmpty
        case "Share Supporter":         return gems.achievements.contains("share")
        case "Premium Member":          return gems.isPremium
        case "Personal Plan Level 1":   return streak.completedPlanDays.count >= 1
        case "Personal Plan Level 2":   return streak.completedPlanDays.count >= 3
        case "Personal Plan Level 3":   return streak.completedPlanDays.count >= 7
        case "Appearance Booster":      return gems.achievements.contains("appearance")
        // Recorded by GuardSetupView the first time the shield actually turns
        // on. Used to sit in the default arm below, so it could never be earned.
        case "Content Blocker":         return gems.achievements.contains("blocker")
        default:                        return false
        }
    }
}
