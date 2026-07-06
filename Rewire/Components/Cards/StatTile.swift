import SwiftUI

/// A single live-timer tile (year / month / day / hour / minute / second).
struct StatTile: View {
    let value: Int
    let unit: String

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text("\(value)")
                .font(Theme.Typography.statNumber())
                .foregroundStyle(Theme.Colors.textPrimary)
                .contentTransition(.numericText())
            Text(unit)
                .font(Theme.Typography.subtitle())
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.lg)
        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.md))
    }
}

/// Small labeled stat card (clean days / times watched / wet dream / edging).
struct LabeledStatCard: View {
    var symbol: String? = nil
    var emoji: String? = nil
    var iconColor: Color = Theme.Colors.green
    var iconBackground: Color = Theme.Colors.green
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ZStack {
                Circle().fill(iconBackground)
                if let emoji {
                    Text(emoji).font(.system(size: 18))
                } else if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 0) {
                // Values like "12.91%" or "1 minute" must never wrap mid-word;
                // shrink to fit so every card keeps the same two-line height.
                Text(value)
                    .font(Theme.Typography.statNumber())
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                Text(label)
                    .font(Theme.Typography.subtitle())
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            Spacer(minLength: 0)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
    }
}
