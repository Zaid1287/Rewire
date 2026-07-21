import SwiftUI

/// Final splash (IMG_5439): app logo, "Welcome to Rewire", spinner. Auto-enters
/// the main app after a short beat.
struct WelcomeView: View {
    var onFinish: () -> Void
    @State private var spin = false

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            AppLogo(size: 130)
            Text("Welcome to Rewire")
                .font(Theme.Typography.title())
                .foregroundStyle(Theme.Colors.textPrimary)

            Image(systemName: "rays")
                .font(.system(size: 26))
                .foregroundStyle(Theme.Colors.textSecondary)
                .rotationEffect(.degrees(spin ? 360 : 0))
                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: spin)
                .padding(.top, Theme.Spacing.lg)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { SceneBackground(kind: .void) }
        .onAppear {
            spin = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { onFinish() }
        }
    }
}

#Preview { WelcomeView(onFinish: {}) }
