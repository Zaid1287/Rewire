import SwiftUI

/// Plan radio row (RonLab): quiet glass row, butter ring + fill when selected,
/// price on the right, per-month equivalent underneath. A "BEST VALUE" tab
/// rides the top edge of the popular plan. Used by the paywall sheet, the
/// onboarding paywall, and Settings.
struct PlanCard: View {
    let plan: Plan
    let isSelected: Bool
    var onTap: () -> Void = {}

    /// Per-plan sell copy — presentation-only, so it lives here, not on the model.
    private var cadence: String {
        switch plan.title {
        case "1 month":  "/mo"
        case "1 year":   "/yr"
        default:         "once"
        }
    }
    private var subline: String {
        switch plan.title {
        case "1 month":  "billed monthly"
        case "1 year":   plan.subtitle.replacingOccurrences(of: "only ", with: "")
        default:         "pay once"
        }
    }

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
                    Text(plan.title.capitalized == "1 Month" ? "Monthly"
                         : plan.title.capitalized == "1 Year" ? "Yearly" : "Lifetime")
                        .font(Theme.Typography.value())
                        .foregroundStyle(Theme.Colors.textHi)
                    Text(subline)
                        .font(Theme.Typography.caption())
                        .foregroundStyle(Theme.Colors.textXlo)
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(plan.price)
                        .font(Theme.Typography.value())
                        .foregroundStyle(Theme.Colors.textHi)
                        .monospacedDigit()
                    Text(cadence)
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
    ZStack {
        SceneBackground(kind: .void)
        VStack(spacing: 10) {
            ForEach(SampleData.plans) { plan in
                PlanCard(plan: plan, isSelected: plan.isPopular)
            }
        }
        .padding()
    }
}
