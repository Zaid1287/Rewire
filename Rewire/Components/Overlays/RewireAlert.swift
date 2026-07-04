import SwiftUI

/// iOS-style centered alert (Relapse confirm): title, message, and two stacked-
/// horizontal buttons. Rendered as a custom overlay so it can match the app's
/// dark blurred look and destructive-red confirm.
struct RewireAlert: View {
    let title: String
    let message: String
    let cancelTitle: String
    let confirmTitle: String
    var confirmIsDestructive: Bool = true
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
                .onTapGesture { onCancel() }

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text(title)
                    .font(Theme.Typography.cardTitle())
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text(message)
                    .font(Theme.Typography.body())
                    .foregroundStyle(Theme.Colors.textSecondary)

                HStack(spacing: Theme.Spacing.sm) {
                    Button(action: { Haptics.tap(); onCancel() }) {
                        Text(cancelTitle)
                            .font(Theme.Typography.button())
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Theme.Colors.surface3, in: Capsule())
                    }
                    Button(action: { Haptics.warning(); onConfirm() }) {
                        Text(confirmTitle)
                            .font(Theme.Typography.button())
                            .foregroundStyle(confirmIsDestructive ? Theme.Colors.red : Theme.Colors.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Theme.Colors.surface3, in: Capsule())
                    }
                }
                .padding(.top, Theme.Spacing.xs)
            }
            .buttonStyle(.plain)
            .padding(Theme.Spacing.lg)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Theme.Radius.xl))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.xl).stroke(Theme.Colors.divider, lineWidth: 1))
            .padding(.horizontal, Theme.Spacing.xxl)
        }
        .transition(.opacity)
    }
}
