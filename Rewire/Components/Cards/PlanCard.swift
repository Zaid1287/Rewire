import SwiftUI

/// Vertical pricing card (ChatGPT-plans style): plan name + tag, big price,
/// blurb, and a short feature list. Tap to select — the green border and tint
/// carry the selection. Replaces the old compact PlanRow everywhere plans are
/// chosen (onboarding paywall, PaywallSheet, Settings).
struct PlanCard: View {
    let plan: Plan
    let isSelected: Bool
    var onTap: () -> Void = {}

    /// Per-plan sell copy — presentation-only, so it lives here, not on the model.
    private var per: String {
        switch plan.title {
        case "1 month":  "/ month"
        case "1 year":   "/ year"
        default:         "one time"
        }
    }
    private var blurb: String {
        switch plan.title {
        case "1 month":  "A flexible start."
        case "1 year":   "7-day free trial, then \(plan.subtitle.replacingOccurrences(of: "only ", with: ""))."
        default:         "Pay once, keep it forever."
        }
    }
    private var features: [String] {
        switch plan.title {
        case "1 month":  ["All premium tools", "Cancel any month"]
        case "1 year":   ["7-day free trial", "Save 77% vs monthly", "Cancel anytime"]
        default:         ["Everything in annual", "No renewals, ever"]
        }
    }

    var body: some View {
        Button(action: { Haptics.select(); onTap() }) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Text(plan.title)
                        .font(Theme.Typography.cardTitle())
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Spacer()
                    if plan.isPopular {
                        Text("RECOMMENDED")
                            .font(Theme.Typography.sectionHeader())
                            .foregroundStyle(Theme.Colors.green)
                            .padding(.horizontal, Theme.Spacing.sm)
                            .padding(.vertical, 4)
                            .background(Theme.Colors.green.opacity(0.14), in: Capsule())
                    }
                }

                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.xs) {
                    Text(plan.price)
                        .font(Theme.Typography.statNumber())
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text(per)
                        .font(Theme.Typography.subtitle())
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                Text(blurb)
                    .font(Theme.Typography.subtitle())
                    .foregroundStyle(Theme.Colors.textSecondary)

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    ForEach(features, id: \.self) { feature in
                        HStack(spacing: Theme.Spacing.xs) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Theme.Colors.green)
                            Text(feature)
                                .font(Theme.Typography.caption())
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                    }
                }
                .padding(.top, 2)
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Theme.Colors.green.opacity(0.08) : Theme.Colors.surface,
                        in: RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                    .stroke(isSelected ? Theme.Colors.green : Theme.Colors.divider,
                            lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(PressableButtonStyle())
        .animation(Theme.Motion.quick, value: isSelected)
    }
}

#Preview {
    VStack(spacing: 12) {
        ForEach(SampleData.plans) { plan in
            PlanCard(plan: plan, isSelected: plan.isPopular)
        }
    }
    .padding()
    .background(Theme.Colors.background)
}
