import SwiftUI

/// Full-width gradient capsule label — the shared look behind PrimaryButton
/// and any other full-width 60pt CTA (ShareLink, PhotosPicker, etc.) that
/// needs the identical style without a Button wrapper.
struct PrimaryButtonLabel: View {
    let title: String
    var trailingEmoji: String? = nil
    var background: AnyShapeStyle = AnyShapeStyle(Theme.Colors.primaryGradient)
    var foreground: Color = .white

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Text(title)
            if let trailingEmoji { Text(trailingEmoji) }
        }
        .font(Theme.Typography.button())
        .foregroundStyle(foreground)
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background(background)
        .clipShape(Capsule())
    }
}

/// Full-width indigo pill CTA — "Continue", "Enable Reminders", "Done",
/// "Unlock Premium". The dominant action button across the app.
struct PrimaryButton: View {
    let title: String
    var trailingEmoji: String? = nil
    var background: AnyShapeStyle = AnyShapeStyle(Theme.Colors.primaryGradient)
    var foreground: Color = .white
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            PrimaryButtonLabel(title: title, trailingEmoji: trailingEmoji, background: background, foreground: foreground)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

/// White pill on colored backgrounds ("I'm ready to quit my addiction").
struct SolidPillButton: View {
    let title: String
    var fill: Color = .white
    var textColor: Color = Theme.Colors.scoreRed
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Text(title)
                .font(Theme.Typography.button())
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(fill)
                .clipShape(Capsule())
        }
        .buttonStyle(PressableButtonStyle())
    }
}

/// Subtle press-scale used by all tappable buttons.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(Theme.Motion.quick, value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 20) {
        PrimaryButton(title: "Continue") {}
        PrimaryButton(title: "Unlock Premium", trailingEmoji: "🙌") {}
        SolidPillButton(title: "I'm ready to quit my addiction") {}
    }
    .padding()
    .background(Theme.Colors.background)
}
