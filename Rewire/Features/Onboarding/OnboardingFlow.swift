import SwiftUI

/// Linear onboarding coordinator. Drives the acquisition funnel from the hero
/// carousel through the paywall-style screens into the main app.
struct OnboardingFlow: View {
    @Environment(AppState.self) private var appState

    @State private var step: Step = .hero
    @State private var quizIndex = 0

    /// Gem totals shown in the quiz header per question (IMG_5428–5431).
    private let quizGems = [100, 150, 250, 350]

    /// Funnel (flow-redesign Phase 5 + paywall, Jul 16): hero → social proof →
    /// quiz → score → PAYWALL (soft, multipage, skippable) → comparison →
    /// commit → welcome. The paywall fires at peak motivation (right after the
    /// personalized score) but skipping routes back into the normal sell —
    /// nothing is gated. Cut from the original 10: fake loader, second
    /// testimonials, in-onboarding reminders ask (now contextual post-check-in).
    enum Step: Equatable {
        case hero, socialProof, quiz, score, paywall, benefits, welcome
    }

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()

            Group {
                switch step {
                case .hero:
                    HeroCarouselView { advance(to: .socialProof) }
                case .socialProof:
                    SocialProofView { advance(to: .quiz) }
                case .quiz:
                    quizView
                case .score:
                    ScoreResultView { advance(to: .paywall) }
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
            gemCount: quizGems[min(quizIndex, quizGems.count - 1)],
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
