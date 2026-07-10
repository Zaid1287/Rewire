import SwiftUI

/// My Badges (IMG_5463 / 5464): claimable badges up top, then the long
/// "badges you must collect" list.
struct BadgesView: View {
    @Environment(AppState.self) private var appState
    @Environment(StreakStore.self) private var streak
    @Environment(GemStore.self) private var gems
    @Environment(\.dismiss) private var dismiss

    /// All badges, tagged with their real state: claimed badges render dimmed
    /// (reusing `.locked`'s look), earned-but-unclaimed render claimable, and
    /// everything else stays locked. Kills free-claiming.
    private var allBadges: [Badge] { SampleData.claimableBadges + SampleData.lockedBadges }

    private func state(for badge: Badge) -> Badge.State {
        if gems.claimedBadges.contains(badge.title) { return .locked }
        return BadgeProgress.isEarned(badge, appState: appState, streak: streak, gems: gems) ? .claimable : .locked
    }

    private var claimableNow: [Badge] { allBadges.filter { state(for: $0) == .claimable } }
    private var notClaimable: [Badge] { allBadges.filter { state(for: $0) == .locked } }

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(title: "My Badges", showsBack: true, onBack: { dismiss() })
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        SectionHeader("Deserved Badges")
                        badgeGroup(claimableNow)
                    }
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        SectionHeader("Badges you must collect")
                        badgeGroup(notClaimable)
                    }
                }
                .screenPadding()
                .padding(.top, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.tabBarClearance)
            }
        }
        .background(Theme.Colors.background)
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
    }

    private func badgeGroup(_ badges: [Badge]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(badges.enumerated()), id: \.element.id) { idx, badge in
                BadgeRow(badge: Badge(title: badge.title, requirement: badge.requirement, state: state(for: badge))) {
                    gems.claimBadge(badge.title)
                    gems.award(50)
                    Analytics.capture("badge_claimed", ["badge": badge.title])
                }
                .padding(.horizontal, Theme.Spacing.md)
                if idx < badges.count - 1 { RowDivider(inset: 64) }
            }
        }
        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
    }
}

#Preview {
    NavigationStack { BadgesView() }
        .environment(AppState()).environment(StreakStore()).environment(GemStore())
}
