import SwiftUI

/// Shared paywall sheet (reused by the Panic Button, Settings, and other tabs'
/// "Unlock Premium" entry points). Plan list + subscribe CTA; mock purchase,
/// no StoreKit. Shows a simple "You're Premium" state once unlocked.
struct PaywallSheet: View {
    @Environment(GemStore.self) private var gems
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPlan: Plan = SampleData.plans[1]
    @State private var didSubscribe = false

    var body: some View {
        SheetScaffold(topIcon: "crown.fill", title: gems.isPremium || didSubscribe ? "You're Premium" : "Unlock Premium") {
            if gems.isPremium || didSubscribe {
                premiumState
            } else {
                plansState
            }
        }
        .onAppear { Analytics.capture("paywall_viewed") }
    }

    private var premiumState: some View {
        SuccessView(
            title: "You're Premium",
            subtitle: "All premium features are unlocked. Enjoy the full Rewire experience.",
            buttonTitle: "Done",
            action: { dismiss() }
        )
        .frame(height: 320)
    }

    private var plansState: some View {
        VStack(spacing: Theme.Spacing.lg) {
            VStack(spacing: 0) {
                ForEach(Array(SampleData.plans.enumerated()), id: \.element.id) { idx, plan in
                    PlanRow(plan: plan, isSelected: selectedPlan == plan) { selectedPlan = plan }
                    if idx < SampleData.plans.count - 1 { RowDivider(inset: Theme.Spacing.lg) }
                }
            }
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.lg).stroke(Theme.Colors.divider, lineWidth: 1))
            .screenPadding()

            PrimaryButton(title: "Subscribe", trailingEmoji: "🙌") {
                Haptics.success()
                gems.unlockPremium()
                didSubscribe = true
            }
            .screenPadding()

            Button {
                Haptics.success()
                gems.unlockPremium()
                didSubscribe = true
            } label: {
                Text("Restore Purchase")
                    .font(Theme.Typography.body())
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .padding(.bottom, Theme.Spacing.lg)
        }
    }
}

#Preview {
    PaywallSheet().environment(GemStore())
}
