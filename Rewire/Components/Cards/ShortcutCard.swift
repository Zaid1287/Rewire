import SwiftUI

/// A Home "Shortcuts" tile: icon + TITLE › on top, big value + unit below.
struct ShortcutCard: View {
    let symbol: String
    let title: String
    var tint: Color = Theme.Colors.green
    let value: String
    let unit: String
    var showsChevron: Bool = true
    var action: () -> Void = {}

    var body: some View {
        Button(action: { Haptics.tap(); action() }) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack(spacing: 6) {
                    Image(systemName: symbol).foregroundStyle(tint)
                    Text(title)
                        .font(Theme.Typography.sectionHeader())
                        .tracking(0.5)
                        .textCase(.uppercase)
                        .foregroundStyle(tint)
                    if showsChevron {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(tint)
                    }
                }
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(Theme.Typography.statNumber())
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text(unit)
                        .font(Theme.Typography.body())
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
        }
        .buttonStyle(PressableButtonStyle())
    }
}

/// Wide action card (Relapse / Daily Report): icon+title top-left,
/// caption bottom-right, optional count badge.
struct WideActionCard: View {
    let symbol: String
    let title: String
    var count: Int? = nil
    let caption: String
    var tint: Color = Theme.Colors.textPrimary
    var action: () -> Void = {}

    var body: some View {
        Button(action: { Haptics.tap(); action() }) {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: symbol).foregroundStyle(tint)
                    Text(title)
                        .font(Theme.Typography.headline())
                        .foregroundStyle(tint)
                    if let count { CountBadge(count: count) }
                }
                Text(caption)
                    .font(Theme.Typography.subtitle())
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
        }
        .buttonStyle(PressableButtonStyle())
    }
}
