import SwiftUI

/// A list row: leading icon, title (+ optional POPULAR badge / warning dot),
/// subtitle, trailing chevron. Used on Quit Porn, Recovery, and Settings-ish lists.
struct FeatureRow: View {
    let item: FeatureItem
    var iconColor: Color = Theme.Colors.textPrimary
    var action: () -> Void = {}

    private var isSoon: Bool {
        if case .soon? = item.badge { return true }
        return false
    }

    var body: some View {
        // Soon rows get no haptic — a dead tap must not feel like a live one.
        Button(action: { if !isSoon { Haptics.tap(); action() } }) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: item.symbol)
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(isSoon ? Theme.Colors.textTertiary : iconColor)
                    .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: Theme.Spacing.xs) {
                        Text(item.title)
                            .font(Theme.Typography.headline())
                            .foregroundStyle(isSoon ? Theme.Colors.textTertiary : Theme.Colors.textPrimary)
                        if case .popular? = item.badge { TagBadge(kind: .popular) }
                        if item.warning { WarningDot() }
                        if case .count(let n)? = item.badge { CountBadge(count: n) }
                        if isSoon {
                            // Same treatment as AppearanceView's coming-soon rows.
                            Text("Soon").font(Theme.Typography.caption())
                                .foregroundStyle(Theme.Colors.textTertiary)
                                .padding(.horizontal, 8).padding(.vertical, 2)
                                .background(Theme.Colors.surface2, in: Capsule())
                        }
                    }
                    Text(item.subtitle)
                        .font(Theme.Typography.subtitle())
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: Theme.Spacing.sm)

                if item.showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            }
            .padding(.vertical, Theme.Spacing.md)
        }
        .buttonStyle(.plain)
    }
}
