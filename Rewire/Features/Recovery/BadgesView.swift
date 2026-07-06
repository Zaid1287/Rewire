import SwiftUI

/// My Badges (IMG_5463 / 5464): claimable badges up top, then the long
/// "badges you must collect" list.
struct BadgesView: View {
    @Environment(GemStore.self) private var gems
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(title: "My Badges", showsBack: true, onBack: { dismiss() })
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        SectionHeader("Deserved Badges")
                        badgeGroup(SampleData.claimableBadges)
                    }
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        SectionHeader("Badges you must collect")
                        badgeGroup(SampleData.lockedBadges)
                    }
                }
                .screenPadding()
                .padding(.top, Theme.Spacing.md)
                .padding(.bottom, 120)
            }
        }
        .background(Theme.Colors.background)
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
    }

    private func badgeGroup(_ badges: [Badge]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(badges.enumerated()), id: \.element.id) { idx, badge in
                BadgeRow(badge: gems.claimedBadges.contains(badge.title)
                         ? Badge(title: badge.title, requirement: badge.requirement, state: .locked)
                         : badge) {
                    gems.claimBadge(badge.title)
                    gems.award(50)
                }
                .padding(.horizontal, Theme.Spacing.md)
                if idx < badges.count - 1 { RowDivider(inset: 64) }
            }
        }
        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
    }
}

#Preview { NavigationStack { BadgesView() }.environment(GemStore()) }
