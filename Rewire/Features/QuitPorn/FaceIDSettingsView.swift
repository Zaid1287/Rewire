import SwiftUI

/// Face ID Lock sheet (Quit Porn → Privacy). Mirrors ReminderSettingsView's
/// sheet chrome (drag capsule + title). Turning the toggle on requires a
/// successful Face ID confirmation first, so a user without enrolled
/// biometrics (or who cancels) never locks themselves out.
struct FaceIDSettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var enabled = false

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Capsule().fill(Theme.Colors.textTertiary).frame(width: 40, height: 5)
                .padding(.top, Theme.Spacing.sm)

            Text("Face ID Lock")
                .font(Theme.Typography.title())
                .foregroundStyle(Theme.Colors.textPrimary)

            VStack(spacing: Theme.Spacing.sm) {
                if BiometricAuth.canUseBiometrics {
                    HStack {
                        Text("Lock with Face ID")
                            .font(Theme.Typography.body())
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Spacer()
                        Toggle("", isOn: $enabled)
                            .labelsHidden()
                            .tint(Theme.Colors.green)
                            .onChange(of: enabled) { _, newValue in toggleChanged(newValue) }
                    }
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
                } else {
                    Text("Face ID isn't available on this device.")
                        .font(Theme.Typography.body())
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .padding(Theme.Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
                }
            }
            .screenPadding()

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.Colors.background)
        .onAppear { enabled = appState.faceIDEnabled }
    }

    private func toggleChanged(_ newValue: Bool) {
        Haptics.tap()
        if newValue {
            Task {
                let success = await BiometricAuth.authenticate(reason: "Confirm to enable Face ID lock")
                if success {
                    appState.setFaceIDEnabled(true)
                    appState.isUnlocked = true
                } else {
                    enabled = false
                }
            }
        } else {
            appState.setFaceIDEnabled(false)
        }
    }
}

#Preview { FaceIDSettingsView().environment(AppState()) }
