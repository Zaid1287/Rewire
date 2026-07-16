import SwiftUI

/// The main app shell: a tab-switched content area with the floating custom tab
/// bar overlaid at the bottom. Each tab hosts its own NavigationStack.
struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @Environment(StreakStore.self) private var streak
    @Environment(GemStore.self) private var gems

    /// Earned-but-unclaimed badges — drives the Progress tab badge count.
    private var unclaimedBadges: Int {
        BadgeProgress.unclaimedCount(appState: appState, streak: streak, gems: gems)
    }

    var body: some View {
        @Bindable var appState = appState

        ZStack(alignment: .bottom) {
            Theme.Colors.background.ignoresSafeArea()

            Group {
                switch appState.selectedTab {
                case .today:    HomeView()
                case .progress: ProgressTabView()
                case .toolkit:  ToolkitView()
                case .settings: SettingsView()
                }
            }

            BottomFadeScrim()
                .frame(maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea(edges: .bottom)

            RewireTabBar(selection: $appState.selectedTab,
                         isCollapsed: $appState.dockCollapsed,
                         progressBadgeCount: unclaimedBadges)
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
