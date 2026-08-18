import SwiftUI

/// Benefit row: pastel icon circle + title + subtitle. Used by onboarding to
/// show what recovery actually gives you.
struct BenefitRow: View {
    let benefit: Benefit

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            IconCircle(symbol: benefit.symbol, isEmoji: benefit.isEmoji,
                       tint: benefit.iconTint, background: benefit.iconBackground,
                       stroke: benefit.iconBackground.opacity(0.6))

            VStack(alignment: .leading, spacing: 6) {
                Text(benefit.title)
                    .font(Theme.Typography.headline())
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text(benefit.subtitle)
                    .font(Theme.Typography.subtitle())
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: Theme.Spacing.xs)
        }
        .padding(.vertical, Theme.Spacing.sm)
    }
}
