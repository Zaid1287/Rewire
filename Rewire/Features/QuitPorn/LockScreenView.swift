import SwiftUI

/// Full-screen Face ID gate shown by RootView when `appState.faceIDEnabled`
/// is on and the app is locked (`!appState.isUnlocked`). Auto-attempts
/// authentication once on appear; the button is a fallback for retry after
/// a Cancel or failed attempt.
struct LockScreenView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            AppLogo(size: 120)

            Text("Rewire")
                .font(Theme.Typography.title())
                .foregroundStyle(Theme.Colors.textPrimary)

            Spacer()

            PrimaryButton(title: "Unlock with Face ID") {
                Task { await attemptUnlock() }
            }
            .screenPadding()
            .padding(.bottom, Theme.Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background)
        .onAppear { Task { await attemptUnlock() } }
    }

    private func attemptUnlock() async {
        if await BiometricAuth.authenticate() {
            appState.isUnlocked = true
        }
    }
}

#Preview { LockScreenView().environment(AppState()) }
