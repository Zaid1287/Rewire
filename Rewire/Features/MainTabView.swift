import SwiftUI

/// The main app shell: a tab-switched content area with the floating custom tab
/// bar overlaid at the bottom. Each tab hosts its own NavigationStack.
struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @Environment(StreakStore.self) private var streak
    @Environment(GemStore.self) private var gems

    /// Earned-but-unclaimed badges — drives the Recovery tab badge count.
    private var unclaimedBadges: Int {
        (SampleData.claimableBadges + SampleData.lockedBadges).filter {
            !gems.claimedBadges.contains($0.title)
                && BadgeProgress.isEarned($0, appState: appState, streak: streak, gems: gems)
        }.count
    }

    var body: some View {
        @Bindable var appState = appState

        ZStack(alignment: .bottom) {
            Theme.Colors.background.ignoresSafeArea()

            Group {
                switch appState.selectedTab {
                case .home:      HomeView()
                case .quitPorn:  QuitPornView()
                case .recovery:  RecoveryView()
                case .history:   HistoryView()
                case .settings:  SettingsView()
                }
            }

            LinearGradient(
                colors: [Theme.Colors.background.opacity(0), Theme.Colors.background.opacity(0.85), Theme.Colors.background],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 140)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .ignoresSafeArea(edges: .bottom)
            .allowsHitTesting(false)

            RewireTabBar(selection: $appState.selectedTab, recoveryBadgeCount: unclaimedBadges)
                .padding(.bottom, Theme.Spacing.xs)
        }
    }
}

#Preview {
    MainTabView()
        .environment(AppState())
        .environment(StreakStore())
        .environment(GemStore())
}
