import SwiftUI

/// Full-screen "Saved successfully" / "Test Completed" confirmation: big green
/// check, title, subtitle, and an optional primary action.
struct SuccessView: View {
    var checkColor: Color = Theme.Colors.green
    let title: String
    let subtitle: String
    var buttonTitle: String? = "Done"
    var topContent: AnyView? = nil
    var action: () -> Void = {}

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            if let topContent {
                topContent
                Spacer()
            } else {
                Spacer()
            }

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 92))
                .foregroundStyle(.white, checkColor)
                .transition(.scale(scale: 0.92).combined(with: .opacity))

            VStack(spacing: Theme.Spacing.sm) {
                Text(title)
                    .font(Theme.Typography.title())
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text(subtitle)
                    .font(Theme.Typography.body())
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let buttonTitle {
                PrimaryButton(title: buttonTitle, action: action)
                    .padding(.top, Theme.Spacing.lg)
            }
            Spacer()
        }
        .screenPadding()
    }
}

#Preview {
    ZStack {
        Theme.Colors.background.ignoresSafeArea()
        SuccessView(title: "Saved successfully",
                    subtitle: "You can find this report in the streak detail under the History tab.")
    }
}
