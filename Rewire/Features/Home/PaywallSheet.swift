import SwiftUI

/// Shared paywall sheet (reused by Settings, the post-crisis debrief, and other
/// "Unlock Premium" entry points). RonLab Void scene: benefits first, plan radio
/// rows, one honest CTA. Real StoreKit 2 products — prices and the billing lines
/// come from the App Store, not from us.
///
/// **No free trial and no crisis-moment trigger** — the two patterns competitors'
/// 1★ reviews cluster on. Premium is depth only; everything a person reaches for
/// in a bad moment stays free (PAYWALL-CLUSTER.md, "free core, paid depth").
struct PaywallSheet: View {
    @Environment(GemStore.self) private var gems
    @Environment(Purchases.self) private var purchases
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPlan: Plan?
    @State private var didSubscribe = false
    @State private var failureMessage: String?
    @State private var showPending = false

    /// Plans still worth offering: everything for free users, only strictly
    /// better plans for someone already subscribed (monthly → yearly → lifetime).
    private var availablePlans: [Plan] {
        guard gems.isPremium else { return purchases.plans }
        guard let owned = purchases.plans.firstIndex(where: { $0.id == gems.premiumPlan })
        else { return [] }
        return Array(purchases.plans.dropFirst(owned + 1))
    }

    private var isUpgrade: Bool { gems.isPremium && !didSubscribe && !availablePlans.isEmpty }
    private var isDone: Bool { didSubscribe || (gems.isPremium && availablePlans.isEmpty) }

    /// What Premium actually buys. Everything here is depth over time — nothing
    /// in this list is something a person needs mid-urge.
    private let benefits = [
        "Your full history — every stat past the last 30 days",
        "Slip-pattern insights across every slip you log",
        "The 21-day Personal Plan, day by day",
        "The Appearance Tracker"
    ]

    var body: some View {
        ZStack {
            SceneBackground(kind: .void)
            if isDone {
                premiumState
            } else {
                switch purchases.loadState {
                case .loading: loadingState
                case .failed:  unavailableState
                case .loaded:  plansState
                }
            }
        }
        .task {
            Analytics.capture("paywall_viewed")
            if purchases.loadState != .loaded { await purchases.load() }
        }
        .onChange(of: availablePlans) { _, plans in syncSelection(plans) }
        .onAppear { syncSelection(availablePlans) }
        .rewireAlert(isPresented: failureMessage != nil) {
            RewireAlert(
                title: "Purchase Didn't Go Through",
                message: failureMessage ?? "",
                confirmTitle: "OK",
                confirmIsDestructive: false,
                onCancel: { failureMessage = nil },
                onConfirm: { failureMessage = nil }
            )
        }
        .rewireAlert(isPresented: showPending) {
            RewireAlert(
                title: "Waiting on Approval",
                message: "The App Store needs to approve this purchase. Premium unlocks by itself once it does — nothing else to do.",
                confirmTitle: "OK",
                confirmIsDestructive: false,
                onCancel: { showPending = false },
                onConfirm: { showPending = false }
            )
        }
    }

    /// Keep the selection on a row that still exists, without stomping a choice
    /// the user already made.
    private func syncSelection(_ plans: [Plan]) {
        guard !plans.isEmpty else { selectedPlan = nil; return }
        if let current = selectedPlan, plans.contains(current) { return }
        selectedPlan = plans.first(where: \.isPopular) ?? plans.first
    }

    // MARK: States

    private var loadingState: some View {
        VStack(spacing: Theme.Spacing.md) {
            ProgressView().tint(Theme.Colors.butter)
            Text("Loading plans…")
                .font(Theme.Typography.subtitle())
                .foregroundStyle(Theme.Colors.textLo)
        }
    }

    /// Honest failure. No fallback prices — showing a made-up number when the
    /// App Store is unreachable is how you end up charging something else.
    private var unavailableState: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            Text("Plans aren't loading")
                .font(Theme.Typography.title())
                .foregroundStyle(Theme.Colors.textHi)
            Text("We couldn't reach the App Store. Every recovery tool keeps working — Premium is only the extra depth.")
                .font(Theme.Typography.subtitle())
                .foregroundStyle(Theme.Colors.textLo)
                .multilineTextAlignment(.center)
            Spacer()
            PrimaryButton(title: "Try Again") { Task { await purchases.load() } }
            Button { Haptics.tap(); dismiss() } label: {
                Text("Not now")
                    .font(Theme.Typography.subtitle())
                    .foregroundStyle(Theme.Colors.textLo)
            }
            .padding(.bottom, Theme.Spacing.lg)
        }
        .screenPadding()
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
                Text("Everything is unlocked. Manage or cancel anytime in the App Store.")
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

            (Text(isUpgrade ? "Move up a plan,\n" : "The depth unlocked,\n")
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
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.top, 22)

            // The other half of the deal, stated on the paywall itself.
            Text("Panic, the streak, the blocker and check-ins are free — always, on every plan.")
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Colors.textLo)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 16)

            VStack(spacing: 10) {
                ForEach(availablePlans) { plan in
                    PlanCard(plan: plan, isSelected: selectedPlan == plan) { selectedPlan = plan }
                }
            }
            .padding(.top, 22)

            Spacer(minLength: Theme.Spacing.lg)

            PrimaryButton(title: purchases.isPurchasing ? "Contacting the App Store…"
                                                        : (isUpgrade ? "Upgrade" : "Continue")) {
                guard let plan = selectedPlan else { return }
                Task { await buy(plan) }
            }
            .disabled(purchases.isPurchasing || selectedPlan == nil)

            // Price → renewal, right next to the button. This is the disclosure
            // the billing-trap reviews are about.
            Text(selectedPlan.map { "\($0.disclosure) Cancel anytime in the App Store · restore in Settings." }
                 ?? "Cancel anytime in the App Store · restore in Settings.")
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Colors.textXlo)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                .padding(.bottom, Theme.Spacing.lg)
        }
        .padding(.horizontal, 26)
    }

    private func buy(_ plan: Plan) async {
        switch await purchases.purchase(plan) {
        case .success:
            Haptics.success()
            Analytics.capture("paywall_converted", ["plan": plan.id])
            didSubscribe = true
        case .pending:
            showPending = true
        case .cancelled:
            break
        case .failed(let message):
            failureMessage = message
        }
    }
}

#Preview {
    PaywallSheet()
        .environment(GemStore())
        .environment(Purchases())
}
