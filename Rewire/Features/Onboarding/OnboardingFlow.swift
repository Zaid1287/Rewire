import SwiftUI

/// Linear onboarding coordinator. Drives the acquisition funnel from the hero
/// carousel through the paywall-style screens into the main app.
struct OnboardingFlow: View {
    @Environment(AppState.self) private var appState
    @Environment(Purchases.self) private var purchases

    @State private var step: Step = .hero
    @State private var quizIndex = 0

    /// Funnel (flow-redesign Phase 5 + paywall, Jul 16): hero → consent →
    /// social proof → quiz → score → PAYWALL (soft, multipage, skippable) →
    /// comparison → commit → welcome. The paywall fires at peak motivation (right after the
    /// personalized score) but skipping routes back into the normal sell —
    /// nothing is gated. Cut from the original 10: fake loader, second
    /// testimonials, in-onboarding reminders ask (now contextual post-check-in).
    enum Step: Equatable {
        case hero, consent, socialProof, quiz, score, paywall, benefits, welcome
    }

    /// The consent screen sits second on purpose. Analytics is off by default
    /// and the Settings toggle only exists after onboarding, so asking any
    /// later means the entire acquisition funnel — every `onboarding_step`,
    /// the paywall shown/skipped pair, `onboarding_completed` — is dropped for
    /// every user who ever installs. Asking here is the difference between
    /// having that funnel and not. It follows the hero rather than opening the
    /// app because the hero is where we make the "no account, no cloud" promise,
    /// and the honest place to ask is right after the claim.

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()

            Group {
                switch step {
                case .hero:
                    HeroCarouselView { advance(to: .consent) }
                case .consent:
                    AnalyticsConsentView { granted in
                        // Same setter Settings uses, so there is one consent
                        // path in the app and Settings reflects this answer.
                        appState.setAnalyticsOptIn(granted)
                        // Deliberately after the setter: when the answer is
                        // yes, this is the first event that can be captured,
                        // and it marks the top of the measurable funnel.
                        advance(to: .socialProof)
                    }
                case .socialProof:
                    SocialProofView { advance(to: .quiz) }
                case .quiz:
                    quizView
                case .score:
                    // Skip the paywall entirely when there is nothing to sell —
                    // otherwise the funnel's biggest moment is a screen that
                    // reads "Plans aren't loading". Restores itself the moment
                    // App Store Connect has products.
                    ScoreResultView { advance(to: purchases.canSell ? .paywall : .benefits) }
                case .paywall:
                    OnboardingPaywallView(
                        onSkip: { advance(to: .benefits) },
                        // Already sold — skip the remaining sell, go straight in.
                        onPurchased: { advance(to: .welcome) }
                    )
                case .benefits:
                    BenefitsView { advance(to: .welcome) }
                case .welcome:
                    WelcomeView { appState.finishOnboarding() }
                }
            }
            // Funnel only moves forward at the step level (quiz back is
            // internal to the quiz step), so the push direction is constant.
            .transition(.push(forward: true))
        }
        .animation(Theme.Motion.enter, value: step)
    }

    private var quizView: some View {
        let q = SampleData.quizQuestions[quizIndex]
        return QuestionScaffold(
            showsBack: quizIndex > 0,
            onBack: { withAnimation(Theme.Motion.standard) { quizIndex -= 1 } },
            progress: quizIndex == 0 ? nil : Double(quizIndex) / Double(SampleData.quizQuestions.count),
            question: q.prompt
        ) {
            ForEach(Array(q.options.enumerated()), id: \.offset) { idx, option in
                QuizOptionRow(letter: idx.optionLetter, text: option) {
                    answerQuiz(optionIndex: idx)
                }
            }
        }
    }

    private func answerQuiz(optionIndex: Int) {
        appState.recordAnswer(questionIndex: quizIndex, optionIndex: optionIndex)
        if quizIndex < SampleData.quizQuestions.count - 1 {
            withAnimation(Theme.Motion.standard) { quizIndex += 1 }
        } else {
            advance(to: .score)
        }
    }

    private func advance(to next: Step) {
        Analytics.capture("onboarding_step", ["step": String(describing: next)])
        if next == .welcome { Analytics.capture("onboarding_completed") }
        withAnimation(Theme.Motion.enter) { step = next }
    }
}
