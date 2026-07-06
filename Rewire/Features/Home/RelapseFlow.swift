import SwiftUI

/// Post-relapse flow (IMG_5445 → 5446 → 5447): pick reason(s) → "regretful?" →
/// saved confirmation with an encouraging reminder. Resets the streak on entry.
struct RelapseFlow: View {
    @Environment(StreakStore.self) private var streak
    @Environment(GemStore.self) private var gems
    @Environment(\.dismiss) private var dismiss

    @State private var step: Step = .reasons
    @State private var selectedReasons: Set<String> = []
    @State private var regretful: Bool? = nil

    enum Step { case reasons, regret, saved }

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            switch step {
            case .reasons: reasonsView
            case .regret:  regretView
            case .saved:   savedView
            }
        }
        .animation(.easeInOut(duration: 0.3), value: step)
        .onAppear {
            streak.relapse()
            // Costs 500 coins per the copy, but a relapse report is never blocked
            // on affordability — spend if possible, proceed regardless.
            gems.spendCoins(500)
        }
    }

    private var reasonsView: some View {
        QuestionScaffold(
            showsBack: true,
            onBack: { dismiss() },
            progress: 0.33,
            question: "What were the main reasons for this relapse?",
            subtitle: "Pick at least one reason."
        ) {
            ForEach(SampleData.relapseReasons, id: \.self) { reason in
                RadioOptionRow(text: reason, isSelected: selectedReasons.contains(reason)) {
                    if selectedReasons.contains(reason) { selectedReasons.remove(reason) }
                    else { selectedReasons.insert(reason) }
                }
            }
            PrimaryButton(title: "Continue") {
                guard !selectedReasons.isEmpty else { Haptics.warning(); return }
                step = .regret
            }
            .padding(.top, Theme.Spacing.sm)
            .opacity(selectedReasons.isEmpty ? 0.5 : 1)
        }
    }

    private var regretView: some View {
        QuestionScaffold(
            showsBack: true,
            onBack: { step = .reasons },
            progress: 0.66,
            question: "Do you feel regretful right now?"
        ) {
            QuizOptionRow(letter: "A", text: "Yes, I am regretful 😥") { regretful = true; step = .saved }
            QuizOptionRow(letter: "B", text: "No, not yet.") { regretful = false; step = .saved }
        }
    }

    private var savedView: some View {
        VStack(spacing: 0) {
            ProgressBarView(value: 1, height: 8)
                .screenPadding()
                .padding(.top, Theme.Spacing.xxl)

            // Encouraging reminder
            VStack(spacing: 2) {
                Text("A reminder for you:")
                    .font(Theme.Typography.body())
                    .foregroundStyle(Theme.Colors.green)
                (Text("A relapse ").foregroundStyle(Theme.Colors.textPrimary)
                 + Text("cannot").foregroundStyle(Theme.Colors.flame)
                 + Text(" make you give up.").foregroundStyle(Theme.Colors.textPrimary))
                    .font(Theme.Typography.cardTitle())
                    .fontWeight(.bold)
            }
            .multilineTextAlignment(.center)
            .padding(Theme.Spacing.lg)
            .frame(maxWidth: .infinity)
            .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
            .screenPadding()
            .padding(.top, Theme.Spacing.xl)

            SuccessView(
                title: "Saved successfully",
                subtitle: "You can find this report in the streak detail under the History tab.",
                buttonTitle: "Done",
                action: { dismiss() }
            )
        }
        .background(Theme.Colors.background)
        .onAppear { Haptics.success() }
    }
}
