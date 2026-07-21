import SwiftUI

/// Post-quiz multipage paywall (Zaid, Jul 16). Fires right after the score
/// reveal — peak motivation — and pitches across three swipeable pages:
/// 1. the personalized plan (score-aware), 2. social proof, 3. plans.
///
/// Deliberately SOFT, unlike QUITTR's (their #1 complaint source, 70% 1★):
/// skippable from page one via the X, an explicit "Continue with free version"
/// on the plans page, trial-first framing with "no payment due today · cancel
/// anytime" spelled out, and no content gated behind it — skipping continues
/// the normal onboarding sell (comparison → commit).
struct OnboardingPaywallView: View {
    @Environment(AppState.self) private var appState
    @Environment(GemStore.self) private var gems
    var onSkip: () -> Void
    var onPurchased: () -> Void

    @State private var page = 0
    /// Annual preselected — the trial carrier and the anchor.
    @State private var selectedPlan: Plan = SampleData.plans[1]

    private var isLastPage: Bool { page == 2 }

    var body: some View {
        VStack(spacing: 0) {
            header

            TabView(selection: $page) {
                planReadyPage.tag(0)
                proofPage.tag(1)
                plansPage.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(Theme.Motion.enter, value: page)

            footer
        }
        .background { SceneBackground(kind: .void) }
        .onAppear { Analytics.capture("onboarding_paywall_shown") }
    }

    // MARK: Chrome

    private var header: some View {
        HStack {
            // Custom dots (the system page indicator is invisible on dark).
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
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
                    purchase()
                } else {
                    withAnimation(Theme.Motion.enter) { page += 1 }
                }
            }

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
        switch selectedPlan.title {
        case "1 year":   return "Start my 7-day free trial"
        case "Lifetime": return "Unlock Lifetime"
        default:         return "Start Monthly"
        }
    }

    private var microcopy: String {
        guard isLastPage else { return "Skippable anytime — the crisis tools stay free." }
        switch selectedPlan.title {
        case "1 year":   return "✓ No payment due today · Cancel anytime"
        case "Lifetime": return "One-time purchase · Yours forever"
        default:         return "✓ Cancel anytime"
        }
    }

    private func purchase() {
        // Mock purchase — StoreKit lands later; this flips the same premium
        // flag the rest of the app already keys off.
        gems.unlockPremium(plan: selectedPlan.title == "1 year" ? "1 year (trial)" : selectedPlan.title)
        Haptics.success()
        Analytics.capture("onboarding_paywall_converted", ["plan": selectedPlan.title])
        onPurchased()
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
                    featureRow("waveform.path.ecg", "Urge-wave Panic mode",
                               "Ride the full 10–15 min wave with per-minute rewards.")
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

    // MARK: Page 2 — proof

    private var proofPage: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                VStack(spacing: Theme.Spacing.xs) {
                    Text("🏆")
                        .font(.system(size: 44))
                    Text("It works. They'll tell you.")
                        .font(Theme.Typography.title())
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                    Text("#1 Quit Porn Addiction App")
                        .font(Theme.Typography.subtitle())
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                ForEach(SampleData.quoteTestimonials.prefix(3)) { quote in
                    TestimonialQuoteCard(item: quote)
                }
            }
            .screenPadding()
            .padding(.top, Theme.Spacing.lg)
        }
    }

    // MARK: Page 3 — plans

    private var plansPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Choose your plan.")
                        .font(Theme.Typography.title())
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text("Annual includes a 7-day free trial — cancel before it ends and pay nothing.")
                        .font(Theme.Typography.body())
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                VStack(spacing: Theme.Spacing.sm) {
                    ForEach(SampleData.plans) { plan in
                        PlanCard(plan: plan, isSelected: selectedPlan == plan) { selectedPlan = plan }
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
        .environment(GemStore())
}
