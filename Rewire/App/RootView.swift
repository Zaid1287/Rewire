import SwiftUI

/// Switches between the onboarding funnel and the main tab bar.
struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()

            switch appState.phase {
            case .onboarding:
                OnboardingFlow()
                    .transition(.opacity)
            case .main:
                MainTabView()
                    .transition(.opacity)
            }
        }
    }
}

#Preview {
    RootView()
        .environment(AppState())
        .environment(StreakStore())
        .environment(GemStore())
}
