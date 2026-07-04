import SwiftUI

/// A bottom-sheet style container with a grab handle. Used for the goal-detail
/// / masturbation-session pickers presented over the current screen.
struct SheetScaffold<Content: View>: View {
    var topIcon: String? = nil
    var title: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Capsule()
                .fill(Theme.Colors.textTertiary)
                .frame(width: 40, height: 5)
                .padding(.top, Theme.Spacing.sm)

            if let topIcon {
                Image(systemName: topIcon)
                    .font(.system(size: 30, weight: .regular))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .frame(width: 60, height: 60)
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md)
                        .stroke(Theme.Colors.textPrimary, lineWidth: 2))
            }
            if let title {
                Text(title)
                    .font(Theme.Typography.title())
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
            }
            content
        }
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.surface)
    }
}
