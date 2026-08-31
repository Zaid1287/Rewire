import SwiftUI

/// Plan radio row (RonLab): quiet glass row, butter ring + fill when selected,
/// price on the right, the billing line underneath. A "BEST VALUE" tab rides
/// the top edge of the popular plan. Purely presentational — every string comes
/// off the `Plan`, which comes off a real StoreKit product.
struct PlanCard: View {
    let plan: Plan
    let isSelected: Bool
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: { Haptics.select(); onTap() }) {
            HStack(spacing: 14) {
                // Radio
                Circle()
                    .strokeBorder(isSelected ? Theme.Colors.butter : Color.white.opacity(0.3),
                                  lineWidth: 1.5)
                    .frame(width: 20, height: 20)
                    .overlay {
                        if isSelected {
                            Circle().fill(Theme.Colors.butter).frame(width: 10, height: 10)
                        }
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.name)
                        .font(Theme.Typography.value())
                        .foregroundStyle(Theme.Colors.textHi)
                    Text(plan.subtitle)
                        .font(Theme.Typography.caption())
                        .foregroundStyle(Theme.Colors.textXlo)
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(plan.price)
                        .font(Theme.Typography.value())
                        .foregroundStyle(Theme.Colors.textHi)
                        .monospacedDigit()
                    Text(plan.cadence)
                        .font(Theme.Typography.caption())
                        .foregroundStyle(Theme.Colors.textXlo)
                }
            }
            .padding(.horizontal, 20)
            .frame(height: 62)
            .background(isSelected ? Theme.Colors.butter.opacity(0.07) : Color.white.opacity(0.05),
                        in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(isSelected ? Theme.Colors.butter : Color.white.opacity(0.10),
                                  lineWidth: isSelected ? 1.5 : 1)
            )
            .overlay(alignment: .topTrailing) {
                if plan.isPopular {
                    Text("BEST VALUE")
                        .font(Theme.Typography.unitSuffix(10))
                        .tracking(0.6)
                        .foregroundStyle(Color(hex: 0x141416))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.Colors.butter, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .offset(x: -16, y: -9)
                }
            }
        }
        .buttonStyle(PressableButtonStyle())
        .animation(Theme.Motion.quick, value: isSelected)
    }
}

#Preview {
    // Previews can't construct a StoreKit Product, so the rows are hand-built
    // here. Everything at runtime comes from Purchases.orderedPlans(from:).
    let plans = [
        Plan(id: "monthly", name: "Monthly", subtitle: "billed monthly", price: "$4.99",
             cadence: "/mo", disclosure: "$4.99 per month, renews until you cancel.",
             isPopular: false),
        Plan(id: "yearly", name: "Yearly", subtitle: "$2.49 a month, billed yearly",
             price: "$29.99", cadence: "/yr",
             disclosure: "$29.99 per year, renews until you cancel.", isPopular: true),
        Plan(id: "lifetime", name: "Lifetime", subtitle: "pay once, keep it forever",
             price: "$59.99", cadence: "once",
             disclosure: "$59.99 once. Not a subscription — nothing renews.", isPopular: false)
    ]
    return ZStack {
        SceneBackground(kind: .void)
        VStack(spacing: 10) {
            ForEach(plans) { plan in
                PlanCard(plan: plan, isSelected: plan.isPopular)
            }
        }
        .padding()
    }
}
