import SwiftUI

/// Linear onboarding coordinator. Drives the acquisition funnel from the hero
/// carousel through the paywall-style screens into the main app.
struct OnboardingFlow: View {
    @Environment(AppState.self) private var appState

    @State private var step: Step = .hero
    @State private var quizIndex = 0

    /// Gem totals shown in the quiz header per question (IMG_5428–5431).
    private let quizGems = [100, 150, 250, 350]

    enum Step: Equatable {
        case hero, socialProof, quiz, preparing, score, comparison, benefits,
             moreTestimonials, reminders, welcome
    }

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()

            switch step {
            case .hero:
                HeroCarouselView { advance(to: .socialProof) }
            case .socialProof:
                SocialProofView { advance(to: .quiz) }
            case .quiz:
                quizView
            case .preparing:
                TestCompletedView { advance(to: .score) }
            case .score:
                ScoreResultView { advance(to: .comparison) }
            case .comparison:
                ComparisonView { advance(to: .benefits) }
            case .benefits:
                BenefitsView { advance(to: .moreTestimonials) }
            case .moreTestimonials:
                MoreTestimonialsView { advance(to: .reminders) }
            case .reminders:
                RemindersView(
                    onEnable: { hour, minute in
                        Task {
                            let granted = await ReminderScheduler.requestPermission()
                            if granted {
                                appState.setReminder(enabled: true, hour: hour, minute: minute)
                                ReminderScheduler.scheduleDaily(hour: hour, minute: minute)
                            }
                            advance(to: .welcome)
                        }
                    },
                    onLater: { advance(to: .welcome) }
                )
            case .welcome:
                WelcomeView { appState.finishOnboarding() }
            }
        }
        .animation(Theme.Motion.standard, value: step)
    }

    private var quizView: some View {
        let q = SampleData.quizQuestions[quizIndex]
        return QuestionScaffold(
            showsBack: quizIndex > 0,
            onBack: { withAnimation { quizIndex -= 1 } },
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
            withAnimation { quizIndex += 1 }
        } else {
            advance(to: .preparing)
        }
    }

    private func advance(to next: Step) {
        Analytics.capture("onboarding_step", ["step": String(describing: next)])
        if next == .welcome { Analytics.capture("onboarding_completed") }
        withAnimation { step = next }
    }
}
