import SwiftUI

/// Post-quiz multipage paywall (Zaid, Jul 16). Fires right after the score
/// reveal — peak motivation — and pitches across two swipeable pages:
/// 1. the personalized plan (score-aware), 2. plans. (A fabricated "social
/// proof" page with a "#1 app" claim + invented testimonials was cut — App
/// Store 1.4.1/2.3.1 risk and dishonest before the app has shipped.)
///
/// Deliberately SOFT, unlike QUITTR's (their #1 complaint source, 70% 1★):
/// skippable from page one via the X, an explicit "Continue with free version"
/// on the plans page, `price → renewal period` stated next to the CTA, and
/// **no free trial** — nothing auto-charges after a window the user forgot
/// about. Skipping costs nothing: every crisis, streak, blocker and check-in
/// tool is free forever, so onboarding continues normally (comparison → commit).
struct OnboardingPaywallView: View {
    @Environment(AppState.self) private var appState
    @Environment(Purchases.self) private var purchases
    var onSkip: () -> Void
    var onPurchased: () -> Void

    @State private var page = 0
    /// Yearly preselected — the anchor, and the plan marked BEST VALUE.
    @State private var selectedPlan: Plan?
    @State private var failureMessage: String?

    private var isLastPage: Bool { page == 1 }

    var body: some View {
        VStack(spacing: 0) {
            header

            TabView(selection: $page) {
                planReadyPage.tag(0)
                plansPage.tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(Theme.Motion.enter, value: page)

            footer
        }
        .background { SceneBackground(kind: .void) }
        .task {
            Analytics.capture("onboarding_paywall_shown")
            if purchases.loadState != .loaded { await purchases.load() }
        }
        .onChange(of: purchases.plans) { _, plans in
            if selectedPlan == nil || !plans.contains(selectedPlan!) {
                selectedPlan = plans.first(where: \.isPopular) ?? plans.first
            }
        }
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
    }

    // MARK: Chrome

    private var header: some View {
        HStack {
            // Custom dots (the system page indicator is invisible on dark).
            HStack(spacing: 6) {
                ForEach(0..<2, id: \.self) { i in
                    Capsule()
                        .fill(i == page ? Theme.Colors.butter : Theme.Colors.surface3)
                        .frame(width: i == page ? 24 : 14, height: 5)
                }
            }
            Spacer()
            // Skippable from page one — the soft-paywall contract.
            Button {
                Haptics.tap()
                Analytics.capture("onboarding_paywall_skipped")
                onSkip()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
        }
        .screenPadding()
        .padding(.top, Theme.Spacing.sm)
    }

    private var footer: some View {
        VStack(spacing: Theme.Spacing.sm) {
            PrimaryButton(title: ctaTitle) {
                if isLastPage {
                    if let plan = selectedPlan { Task { await purchase(plan) } }
                } else {
                    withAnimation(Theme.Motion.enter) { page += 1 }
                }
            }
            .disabled(isLastPage && (selectedPlan == nil || purchases.isPurchasing))

            Text(microcopy)
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Colors.textSecondary)
                .contentTransition(.opacity)
                .animation(Theme.Motion.quick, value: microcopy)

            if isLastPage {
                Button {
                    Haptics.tap()
                    Analytics.capture("onboarding_paywall_skipped")
                    onSkip()
                } label: {
                    Text("Continue with the free version")
                        .font(Theme.Typography.subtitle())
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .underline()
                }
                .transition(.opacity)
            }
        }
        .screenPadding()
        .padding(.bottom, Theme.Spacing.lg)
        .animation(Theme.Motion.enter, value: isLastPage)
    }

    private var ctaTitle: String {
        guard isLastPage else { return "Continue" }
        if purchases.isPurchasing { return "Contacting the App Store…" }
        guard let plan = selectedPlan else { return "Continue" }
        return plan.id == Purchases.ProductID.lifetime ? "Unlock Lifetime" : "Start \(plan.name)"
    }

    /// Word-for-word the same disclosure the Settings paywall shows — the two
    /// surfaces used to contradict each other on the trial.
    private var microcopy: String {
        guard isLastPage else { return "Skippable anytime — the recovery tools are free either way." }
        guard let plan = selectedPlan else { return "Cancel anytime in the App Store." }
        return "\(plan.disclosure) Cancel anytime in the App Store."
    }

    private func purchase(_ plan: Plan) async {
        switch await purchases.purchase(plan) {
        case .success:
            Haptics.success()
            Analytics.capture("onboarding_paywall_converted", ["plan": plan.id])
            onPurchased()
        case .pending:
            // Ask-to-Buy: don't hold onboarding hostage. Premium unlocks itself
            // through Transaction.updates when the approval lands.
            onSkip()
        case .cancelled:
            break
        case .failed(let message):
            failureMessage = message
        }
    }

    // MARK: Page 1 — the personalized plan

    private var planReadyPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Your recovery plan is ready.")
                        .font(Theme.Typography.title())
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text("Score \(appState.addictionScore)/100 — fully reversible. Most members feel the shift inside the first 30 days.")
                        .font(Theme.Typography.body())
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                VStack(spacing: 0) {
                    featureRow("chart.xyaxis.line", "Your full history",
                               "Every stat past the last 30 days, and the trends across them.")
                    RowDivider(inset: 56)
                    featureRow("sparkles", "Slip-pattern insights",
                               "Find the fingerprint behind your slips — and break it.")
                    RowDivider(inset: 56)
                    featureRow("21.circle", "21-day Personal Plan",
                               "A day-by-day path out, built around your quiz answers.")
                    RowDivider(inset: 56)
                    featureRow("camera.fill", "Appearance Tracker",
                               "Watch the change happen, photo by photo.")
                }
                .smokedGlass(radius: 24)

                Text("Panic, the streak, the blocker and daily check-ins are free — always. Premium is the depth on top.")
                    .font(Theme.Typography.caption())
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .screenPadding()
            .padding(.top, Theme.Spacing.lg)
        }
    }

    private func featureRow(_ symbol: String, _ title: String, _ subtitle: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Image(systemName: symbol)
                .font(.system(size: 22))
                .foregroundStyle(Theme.Colors.butter)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.Typography.headline())
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text(subtitle)
                    .font(Theme.Typography.subtitle())
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(Theme.Spacing.md)
    }

    // MARK: Page 2 — plans

    private var plansPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Choose your plan.")
                        .font(Theme.Typography.title())
                        .foregroundStyle(Theme.Colors.textPrimary)
                    // No trial to explain: monthly is the trial, and nothing
                    // auto-charges at the end of a window you forgot about.
                    Text("No free trial to forget about — you're charged what the button says, when you tap it.")
                        .font(Theme.Typography.body())
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                switch purchases.loadState {
                case .loading:
                    ProgressView().tint(Theme.Colors.butter)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.lg)
                case .failed:
                    // No fallback prices, ever. Free is the honest exit here.
                    Text("Plans aren't loading — we couldn't reach the App Store. Continue free below; nothing you need is behind this.")
                        .font(Theme.Typography.subtitle())
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                case .loaded:
                    VStack(spacing: Theme.Spacing.sm) {
                        ForEach(purchases.plans) { plan in
                            PlanCard(plan: plan, isSelected: selectedPlan == plan) { selectedPlan = plan }
                        }
                    }
                }

                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "lock.fill").font(.system(size: 11))
                    Text("Everything stays on your phone. No account needed.")
                }
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Colors.textTertiary)
            }
            .screenPadding()
            .padding(.top, Theme.Spacing.lg)
        }
    }
}

#Preview {
    OnboardingPaywallView(onSkip: {}, onPurchased: {})
        .environment(AppState())
        .environment(Purchases())
}
