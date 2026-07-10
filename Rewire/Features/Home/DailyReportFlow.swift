import SwiftUI

/// Daily Report flow (IMG_5450 → 5454): three yes/no checks (porn, masturbation,
/// relapse), a free-text "how was your day?", then a saved confirmation card.
struct DailyReportFlow: View {
    @Environment(StreakStore.self) private var streak
    @Environment(\.dismiss) private var dismiss

    @State private var step = 0
    @State private var watchedPorn = false
    @State private var masturbated = false
    @State private var relapsed = false
    @State private var note = ""

    private let total = 5   // 3 questions + text + saved

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            switch step {
            case 0: yesNo(question: "I didn't watch porn today.",
                          noLabel: "No, I did watch. 😥") { watchedPorn = $0; next() }
            case 1: yesNo(question: "I didn't masturbate today.",
                          noLabel: "No, I did. 😥") { masturbated = $0; next() }
            case 2: yesNo(question: "I didn't relapse today.",
                          noLabel: "No, I have relapsed. 😥") { relapsed = $0; next() }
            case 3: noteView
            default: savedView
            }
        }
        .animation(Theme.Motion.standard, value: step)
    }

    private func next() { step += 1 }

    /// "No" means the negative behavior happened → flag is true.
    private func yesNo(question: String, noLabel: String, set: @escaping (Bool) -> Void) -> some View {
        QuestionScaffold(
            showsBack: step > 0,
            onBack: { step -= 1 },
            progress: Double(step + 1) / Double(total),
            question: question
        ) {
            QuizOptionRow(letter: "A", text: "Yes, win 💪") { set(false) }
            QuizOptionRow(letter: "B", text: noLabel) { set(true) }
        }
    }

    private var noteView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                CircleBackButton { step -= 1 }
                Spacer()
            }
            .screenPadding()
            .padding(.top, Theme.Spacing.xs)

            ProgressBarView(value: Double(step + 1) / Double(total), height: 8)
                .screenPadding()
                .padding(.top, Theme.Spacing.sm)

            Text("HOW WAS YOUR DAY?")
                .sectionHeaderStyle()
                .screenPadding()
                .padding(.top, Theme.Spacing.xl)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .fill(Theme.Colors.surface)
                    .frame(height: 220)
                if note.isEmpty {
                    Text("Type here how your day was and press Done.")
                        .font(Theme.Typography.cardTitle())
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .padding(Theme.Spacing.md)
                }
                TextEditor(text: $note)
                    .font(Theme.Typography.cardTitle())
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .scrollContentBackground(.hidden)
                    .padding(Theme.Spacing.sm)
                    .frame(height: 220)
            }
            .screenPadding()
            .padding(.top, Theme.Spacing.sm)

            PrimaryButton(title: "Done") {
                streak.saveReport(DailyReport(
                    dayNumber: 1, date: Date(),
                    watchedPorn: watchedPorn, masturbated: masturbated,
                    relapsed: relapsed, note: note))
                Analytics.capture("report_filed")   // never the P/M/O flags
                step += 1
            }
            .screenPadding()
            .padding(.top, Theme.Spacing.md)

            Spacer()
        }
        .background(Theme.Colors.background)
    }

    private var savedView: some View {
        VStack(spacing: 0) {
            ProgressBarView(value: 1, height: 8)
                .screenPadding()
                .padding(.top, Theme.Spacing.xxl)

            // Report summary card
            Card(padding: Theme.Spacing.md) {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    HStack {
                        HStack(spacing: Theme.Spacing.xs) {
                            Image(systemName: "clock").foregroundStyle(Theme.Colors.textSecondary)
                            Text("Day 1").font(Theme.Typography.headline())
                                .foregroundStyle(Theme.Colors.textPrimary)
                            Text("|  \(RewireDate.full.string(from: Date()))")
                                .font(Theme.Typography.body())
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                        Spacer()
                        HStack(spacing: Theme.Spacing.xs) {
                            pmoLetter("P", on: watchedPorn)
                            pmoLetter("M", on: masturbated)
                            pmoLetter("O", on: relapsed)
                        }
                    }
                    Text(note.isEmpty ? "-" : note)
                        .font(Theme.Typography.body())
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .screenPadding()
            .padding(.top, Theme.Spacing.xl)

            SuccessView(
                title: "Saved successfully",
                subtitle: "Please come back here tomorrow and save your daily report.",
                buttonTitle: "Done",
                action: { dismiss() }
            )
        }
        .background(Theme.Colors.background)
        .onAppear { Haptics.success() }
    }

    private func pmoLetter(_ s: String, on: Bool) -> some View {
        Text(s)
            .font(Theme.Typography.headline())
            .foregroundStyle(on ? Theme.Colors.green : Theme.Colors.textTertiary)
    }
}
