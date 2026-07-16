import SwiftUI

/// Slip Log — replaces the old RelapseFlow (flow-redesign Phase 2, plan §3).
/// Recovery starts when shame drops (Reddit finding #4), so this logs a *pattern*
/// instead of extracting regret: when / trigger / feeling, an insight in return,
/// and a forward-looking exit. Differences from the old flow, all deliberate:
/// no 500-coin charge, no "are you regretful?" step, no 😥 / flame "cannot"
/// styling, and the streak resets on **save**, not on entry — so backing out
/// costs nothing, and a misreport is undoable until midnight.
struct SlipLogFlow: View {
    @Environment(StreakStore.self) private var streak
    @Environment(\.dismiss) private var dismiss

    @State private var step: Step = .log
    @State private var forward = true
    @State private var timeOfDay: String?
    @State private var trigger: String?
    @State private var feeling: String?
    /// The saved event, kept so the confirmation can offer undo on exactly it.
    @State private var loggedEvent: StreakEvent?

    enum Step { case log, saved }

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            Group {
                switch step {
                case .log:   logView
                case .saved: savedView
                }
            }
            .transition(.push(forward: forward))
        }
        .animation(Theme.Motion.enter, value: step)
        .onAppear { Analytics.capture("slip_log_opened") }
    }

    // MARK: Log the pattern

    private var logView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                CircleBackButton { dismiss() }
                Spacer()
            }
            .screenPadding()
            .padding(.top, Theme.Spacing.xs)

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Log the pattern.")
                            .font(Theme.Typography.title())
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Text("Slips have fingerprints. Finding yours is how this ends.")
                            .font(Theme.Typography.body())
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }

                    ChipGroup(title: "When did it happen?",
                              options: SampleData.slipTimesOfDay, selection: $timeOfDay)
                    ChipGroup(title: "Trigger",
                              options: SampleData.slipTriggers, selection: $trigger)
                    ChipGroup(title: "Feeling",
                              options: SampleData.slipFeelings, selection: $feeling)
                }
                .screenPadding()
                .padding(.top, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.xxl)
            }

            PrimaryButton(title: "Save & start next run") {
                loggedEvent = streak.logSlip(timeOfDay: timeOfDay, trigger: trigger, feeling: feeling)
                Analytics.capture("slip_logged")   // never the specific chips
                Haptics.success()
                forward = true; step = .saved
            }
            .screenPadding()
            .padding(.bottom, Theme.Spacing.lg)
        }
    }

    // MARK: Saved — insight + forward-looking exit

    private var savedView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.white, Theme.Colors.green)
                .transition(.scale(scale: 0.92).combined(with: .opacity))

            VStack(spacing: Theme.Spacing.sm) {
                Text("Logged. Next run starts now.")
                    .font(Theme.Typography.title())
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                Text("Your record kept every clean day you earned — the slip only reset the current run.")
                    .font(Theme.Typography.body())
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .screenPadding()

            if let insight = streak.slipPatternInsight() {
                HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                    Image(systemName: "sparkles").foregroundStyle(Theme.Colors.purple)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pattern found").font(Theme.Typography.headline())
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Text(insight)
                            .font(Theme.Typography.body())
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    Spacer(minLength: 0)
                }
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.purple.opacity(0.10),
                            in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .stroke(Theme.Colors.purple.opacity(0.35), lineWidth: 1))
                .screenPadding()
            }

            Spacer()

            VStack(spacing: Theme.Spacing.sm) {
                PrimaryButton(title: "I'm re-committed 💪") { dismiss() }
                // Forgiveness for a misreport — undoable until midnight.
                Button("Logged this by mistake? Undo") {
                    if let event = loggedEvent { streak.undoSlip(event) }
                    Haptics.tap()
                    dismiss()
                }
                .font(Theme.Typography.body())
                .foregroundStyle(Theme.Colors.textTertiary)
            }
            .screenPadding()
            .padding(.bottom, Theme.Spacing.lg)
        }
    }
}

#Preview {
    SlipLogFlow()
        .environment(StreakStore())
        .environment(GemStore())
}
