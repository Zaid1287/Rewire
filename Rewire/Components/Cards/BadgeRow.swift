import SwiftUI

/// A single badge row: ribbon glyph + title + requirement, trailing "Claim"
/// (green) when earned. Locked badges have a dimmed ribbon.
struct BadgeRow: View {
    let badge: Badge
    var onClaim: () -> Void = {}

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            RibbonGlyph(active: badge.state == .claimable)

            VStack(alignment: .leading, spacing: 4) {
                Text(badge.title)
                    .font(Theme.Typography.headline())
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text(badge.requirement)
                    .font(Theme.Typography.subtitle())
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: Theme.Spacing.xs)

            if badge.state == .claimable {
                Button(action: { Haptics.success(); onClaim() }) {
                    Text("Claim")
                        .font(Theme.Typography.bodyMedium())
                        .foregroundStyle(Theme.Colors.green)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, Theme.Spacing.sm)
    }
}

/// Award-ribbon icon (purple medallion + tails).
struct RibbonGlyph: View {
    var active: Bool = true
    var body: some View {
        Image(systemName: "rosette")
            .font(.system(size: 30))
            .foregroundStyle(active ? Theme.Colors.purple : Color(hex: 0xB9B3E0).opacity(0.7))
            .frame(width: 44, height: 44)
    }
}
