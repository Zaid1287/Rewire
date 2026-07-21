import SwiftUI

/// Centered nav title with optional leading back button and trailing accessory,
/// rendered as a floating Liquid Glass capsule — content scrolls underneath.
/// `showsDivider` is kept for call-site compatibility but unused: the glass
/// capsule replaces the old full-width bar + hairline.
struct NavHeader<Trailing: View>: View {
    let title: String
    var showsBack: Bool = false
    var onBack: (() -> Void)? = nil
    var showsDivider: Bool = true
    @ViewBuilder var trailing: Trailing

    var body: some View {
        ZStack {
            // Title pill hugs the text — back/trailing float as their own
            // detached glass elements, never crowding the capsule.
            Text(title)
                .font(Theme.Typography.navTitle())
                .foregroundStyle(Theme.Colors.textPrimary)
                .padding(.horizontal, Theme.Spacing.lg)
                .frame(height: 44)
                .liquidGlass(in: Capsule())
                .themeShadow(Theme.Shadows.floating)

            HStack {
                if showsBack {
                    CircleBackButton { onBack?() }
                        .themeShadow(Theme.Shadows.floating)
                }
                Spacer()
                trailing
                    .themeShadow(Theme.Shadows.floating)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.xs)
    }
}

extension NavHeader where Trailing == EmptyView {
    init(title: String, showsBack: Bool = false, showsDivider: Bool = true, onBack: (() -> Void)? = nil) {
        self.init(title: title, showsBack: showsBack, onBack: onBack, showsDivider: showsDivider) { EmptyView() }
    }
}

#Preview {
    VStack(spacing: 0) {
        NavHeader(title: "My Badges", showsBack: true) {}
        NavHeader(title: "Settings") {
            CoinPill(count: 0)
        }
    }
    .background { SceneBackground(kind: .void) }
}
