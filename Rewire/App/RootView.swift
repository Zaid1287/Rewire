import SwiftUI

/// Switches between the onboarding funnel and the main tab bar. Layers the
/// Face ID lock screen on top when enabled and the app isn't unlocked.
struct RootView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.scenePhase) private var scenePhase

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

            if appState.faceIDEnabled && !appState.isUnlocked {
                LockScreenView()
                    .transition(.opacity)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background && appState.faceIDEnabled {
                appState.isUnlocked = false
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
