import SwiftUI

/// iOS-style centered alert (Relapse confirm): title, message, and two stacked-
/// horizontal buttons. Rendered as a custom overlay so it can match the app's
/// dark blurred look and destructive-red confirm.
extension View {
    /// Presents a RewireAlert as an animated overlay. `if flag { RewireAlert }`
    /// inside a bare .overlay inserts with no transaction, so the alert's
    /// pop/fade transition never fires — this wrapper supplies the animation.
    func rewireAlert<A: View>(isPresented: Bool, @ViewBuilder _ alert: () -> A) -> some View {
        overlay {
            Group {
                if isPresented { alert() }
            }
            .animation(Theme.Motion.enter, value: isPresented)
        }
    }
}

struct RewireAlert: View {
    let title: String
    let message: String
    /// Optional — omit for a single-button (confirm-only) alert.
    var cancelTitle: String? = nil
    let confirmTitle: String
    var confirmIsDestructive: Bool = true
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
                .onTapGesture { onCancel() }
                .transition(.opacity)

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text(title)
                    .font(Theme.Typography.cardTitle())
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text(message)
                    .font(Theme.Typography.body())
                    .foregroundStyle(Theme.Colors.textSecondary)

                HStack(spacing: Theme.Spacing.sm) {
                    if let cancelTitle {
                        Button(action: { Haptics.tap(); onCancel() }) {
                            Text(cancelTitle)
                                .font(Theme.Typography.button())
                                .foregroundStyle(Theme.Colors.textPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Theme.Colors.surface3, in: Capsule())
                        }
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
            // Liquid Glass card floating over the scrim.
            .liquidGlass(in: RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous))
            .themeShadow(Theme.Shadows.floating)
            .padding(.horizontal, Theme.Spacing.xxl)
            // Card pops from 0.95 like a system alert; scrim above just fades.
            // Centered modal — scale stays center-anchored, no trigger origin.
            .transition(.scale(scale: 0.95).combined(with: .opacity))
        }
    }
}
