import SwiftUI

/// Benefit / superpower row: pastel icon circle + title + subtitle,
/// optionally with a progress meter and a like counter (Recovery screen).
struct BenefitRow: View {
    let benefit: Benefit
    var showProgress: Bool = false
    var progress: Double = 0.08
    var likeCount: Int? = nil
    var onLike: (() -> Void)? = nil

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
                if showProgress {
                    ProgressBarView(value: progress, height: 6)
                        .padding(.top, 2)
                }
            }
            Spacer(minLength: Theme.Spacing.xs)

            if let likeCount {
                LikeCounter(count: likeCount) { onLike?() }
            }
        }
        .padding(.vertical, Theme.Spacing.sm)
    }
}

/// Pink heart + count pill on the Superpowers list.
struct LikeCounter: View {
    let count: Int
    var action: () -> Void = {}
    var body: some View {
        Button(action: { Haptics.tap(); action() }) {
            HStack(spacing: 6) {
                Image(systemName: "heart")
                    .foregroundStyle(Color(hex: 0xEC6A8C))
                Text("\(count)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textPrimary)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.xs)
            .background(Theme.Colors.surface2, in: RoundedRectangle(cornerRadius: Theme.Radius.md))
        }
        .buttonStyle(.plain)
    }
}
