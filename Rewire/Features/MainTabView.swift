import SwiftUI

/// The main app shell: a tab-switched content area with the floating custom tab
/// bar overlaid at the bottom. Each tab hosts its own NavigationStack.
struct MainTabView: View {
    @Environment(AppState.self) private var appState

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

            RewireTabBar(selection: $appState.selectedTab)
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
