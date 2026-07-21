import SwiftUI

/// Shared paywall sheet (reused by Settings, the post-crisis debrief, and other
/// "Unlock Premium" entry points). RonLab Void scene: benefits first, plan radio
/// rows, one honest CTA. Mock purchase, no StoreKit yet.
/// No auto-charging trial and no crisis-moment trigger — the two patterns
/// competitors' 1★ reviews cluster on.
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
    private var isDone: Bool { didSubscribe || (gems.isPremium && availablePlans.isEmpty) }

    private let benefits = [
        "Unlimited panic & breathing tools",
        "Full history, stats & recovery",
        "Website blocker across every browser",
        "No ads. No account. Local & private."
    ]

    var body: some View {
        ZStack {
            SceneBackground(kind: .void)
            if isDone { premiumState } else { plansState }
        }
        .onAppear {
            Analytics.capture("paywall_viewed")
            if !availablePlans.isEmpty, !availablePlans.contains(selectedPlan) {
                selectedPlan = availablePlans.first!
            }
        }
    }

    private var premiumState: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            TickRing(count: 64, activeFraction: 1,
                     inactiveColor: .white.opacity(0.2),
                     activeColor: Theme.Colors.butter)
                .frame(width: 150, height: 150)
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.system(size: 34, weight: .light))
                        .foregroundStyle(Theme.Colors.textHi)
                }
            VStack(spacing: 8) {
                Text("You're Premium")
                    .font(Theme.Typography.title())
                    .foregroundStyle(Theme.Colors.textHi)
                Text("Everything is unlocked. Nothing else to buy, ever.")
                    .font(Theme.Typography.subtitle())
                    .foregroundStyle(Theme.Colors.textLo)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            PrimaryButton(title: "Done") { dismiss() }
                .screenPadding()
                .padding(.bottom, Theme.Spacing.lg)
        }
    }

    private var plansState: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Rewire Premium".uppercased())
                    .font(Theme.Typography.caption())
                    .tracking(1.4)
                    .foregroundStyle(Theme.Colors.textXlo)
                Spacer()
                Button { Haptics.tap(); dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.Colors.textLo)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.06), in: Circle())
                }
            }
            .padding(.top, Theme.Spacing.lg)

            (Text(isUpgrade ? "Move up a plan,\n" : "Everything unlocked,\n")
                .foregroundStyle(Theme.Colors.textHi)
             + Text("one honest price.").foregroundStyle(Theme.Colors.butter))
                .font(Theme.Typography.title())
                .padding(.top, 12)

            VStack(alignment: .leading, spacing: 13) {
                ForEach(benefits, id: \.self) { benefit in
                    HStack(spacing: 13) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.Colors.butter)
                            .frame(width: 22, height: 22)
                            .background(Theme.Colors.butter.opacity(0.16), in: Circle())
                        Text(benefit)
                            .font(Theme.Typography.subtitle())
                            .foregroundStyle(Theme.Colors.textHi)
                    }
                }
            }
            .padding(.top, 22)

            VStack(spacing: 10) {
                ForEach(availablePlans) { plan in
                    PlanCard(plan: plan, isSelected: selectedPlan == plan) { selectedPlan = plan }
                }
            }
            .padding(.top, 26)

            Spacer(minLength: Theme.Spacing.lg)

            PrimaryButton(title: isUpgrade ? "Upgrade" : "Continue") {
                Haptics.success()
                gems.unlockPremium(plan: selectedPlan.title)
                didSubscribe = true
            }

            Text("No auto-charging trial · cancel anytime · restore in Settings")
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Colors.textXlo)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                .padding(.bottom, Theme.Spacing.lg)
        }
        .padding(.horizontal, 26)
    }
}

#Preview {
    PaywallSheet().environment(GemStore())
}
