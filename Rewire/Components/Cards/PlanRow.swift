import SwiftUI

/// A subscription plan option: radio + title/subtitle + price, POPULAR tag on
/// the highlighted plan. Selected plan shows a green check.
struct PlanRow: View {
    let plan: Plan
    let isSelected: Bool
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: { Haptics.select(); onTap() }) {
            HStack(spacing: Theme.Spacing.md) {
                ZStack {
                    Circle().stroke(isSelected ? Theme.Colors.green : Theme.Colors.textTertiary,
                                    lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(Theme.Colors.green, in: Circle())
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title)
                        .font(Theme.Typography.headline())
                        .foregroundStyle(Theme.Colors.textPrimary)
                    HStack(spacing: Theme.Spacing.xs) {
                        Text(plan.subtitle)
                            .font(Theme.Typography.subtitle())
                            .foregroundStyle(plan.isPopular ? Theme.Colors.green : Theme.Colors.textSecondary)
                        if plan.isPopular {
                            Text("POPULAR")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Theme.Colors.flame, in: RoundedRectangle(cornerRadius: Theme.Radius.xs))
                        }
                    }
                }
                Spacer(minLength: Theme.Spacing.xs)
                Text(plan.price)
                    .font(Theme.Typography.cardTitle())
                    .foregroundStyle(Theme.Colors.textPrimary)
            }
            .padding(Theme.Spacing.md)
            .contentShape(Rectangle())   // whole tile tappable, not just text/icon
        }
        .buttonStyle(.plain)
    }
}
