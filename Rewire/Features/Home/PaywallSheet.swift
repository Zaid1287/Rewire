import SwiftUI

/// Shared paywall sheet (reused by the Panic Button, Settings, and other tabs'
/// "Unlock Premium" entry points). Plan list + subscribe CTA; mock purchase,
/// no StoreKit. Shows a simple "You're Premium" state once unlocked.
struct PaywallSheet: View {
    @Environment(GemStore.self) private var gems
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPlan: Plan = SampleData.plans[1]
    @State private var didSubscribe = false

    /// Plans still worth offering: everything for free users, only strictly
    /// better plans for premium users (monthly → yearly/lifetime, etc.).
    private var availablePlans: [Plan] {
        guard gems.isPremium else { return SampleData.plans }
        let order = SampleData.plans.map(\.title)
        guard let current = order.firstIndex(of: gems.premiumPlan ?? "") else { return [] }
        return SampleData.plans.filter { order.firstIndex(of: $0.title) ?? 0 > current }
    }

    private var isUpgrade: Bool { gems.isPremium && !didSubscribe && !availablePlans.isEmpty }

    private var title: String {
        if didSubscribe || (gems.isPremium && availablePlans.isEmpty) { return "You're Premium" }
        return isUpgrade ? "Upgrade Your Plan" : "Unlock Premium"
    }

    var body: some View {
        SheetScaffold(topIcon: "crown.fill", title: title) {
            if didSubscribe || (gems.isPremium && availablePlans.isEmpty) {
                premiumState
            } else {
                plansState
            }
        }
        .onAppear {
            Analytics.capture("paywall_viewed")
            if !availablePlans.isEmpty, !availablePlans.contains(selectedPlan) {
                selectedPlan = availablePlans.first!
            }
        }
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
            VStack(spacing: Theme.Spacing.sm) {
                ForEach(availablePlans) { plan in
                    PlanCard(plan: plan, isSelected: selectedPlan == plan) { selectedPlan = plan }
                }
            }
            .screenPadding()

            PrimaryButton(title: isUpgrade ? "Upgrade" : "Subscribe", trailingEmoji: "🙌") {
                Haptics.success()
                gems.unlockPremium(plan: selectedPlan.title)
                didSubscribe = true
            }
            .screenPadding()

            Button {
                Haptics.success()
                gems.unlockPremium(plan: "1 year")
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
