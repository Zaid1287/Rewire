import SwiftUI

/// Full-width gradient capsule label — the shared look behind PrimaryButton
/// and any other full-width 60pt CTA (ShareLink, PhotosPicker, etc.) that
/// needs the identical style without a Button wrapper.
struct PrimaryButtonLabel: View {
    let title: String
    var trailingEmoji: String? = nil
    // RonLab primary: white capsule, near-black text — the calm dominant CTA.
    var background: AnyShapeStyle = AnyShapeStyle(Color(hex: 0xF3F2EF))
    var foreground: Color = Color(hex: 0x141416)

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Text(title)
            if let trailingEmoji { Text(trailingEmoji) }
        }
        .font(Theme.Typography.button())
        // Countdown titles (PanicSheet "I'm Safe Now · 0:17") re-render every
        // second; fixed-width digits stop the label jittering. No-op otherwise.
        .monospacedDigit()
        .foregroundStyle(foreground)
        .frame(maxWidth: .infinity)
        .frame(height: 62)
        .background(background)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.35), radius: 18, y: 8)
    }
}

/// Full-width white capsule CTA — "Continue", "Enable Reminders", "Done".
/// The dominant action button across the app.
struct PrimaryButton: View {
    let title: String
    var trailingEmoji: String? = nil
    var background: AnyShapeStyle = AnyShapeStyle(Color(hex: 0xF3F2EF))
    var foreground: Color = Color(hex: 0x141416)
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
    var textColor: Color = Theme.Colors.emberHi
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
    .background { SceneBackground(kind: .void) }
}
