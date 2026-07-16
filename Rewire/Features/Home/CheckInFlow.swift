import SwiftUI

/// Daily check-in — replaces the 5-step DailyReportFlow (flow-redesign Phase 2,
/// plan §4). A daily ritual must be near-instant, so it's one screen: "How was
/// today?" → Clean (instant celebration — the delight budget lives here) or
/// I slipped (routes into the Slip Log, no duplicate interrogation). Presented
/// as a medium-detent sheet, not a full-screen takeover.
struct CheckInFlow: View {
    @Environment(StreakStore.self) private var streak
    @Environment(GemStore.self) private var gems
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var note = ""
    @State private var showSlipLog = false
    @State private var savedClean = false
    /// Contextual reminders ask (Phase 5, plan §7): the permission prompt moved
    /// out of onboarding to here — right after a check-in, when a nightly
    /// reminder's value is concrete.
    @State private var reminderJustSet = false

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            Group {
                if savedClean { celebration } else { ask }
            }
            .transition(.opacity)
        }
        .animation(Theme.Motion.enter, value: savedClean)
        // A slip is a full-screen moment; on its dismiss, close the check-in too.
        .fullScreenCover(isPresented: $showSlipLog, onDismiss: { dismiss() }) {
            SlipLogFlow()
        }
    }

    private var ask: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Capsule().fill(Theme.Colors.surface3)
                .frame(width: 40, height: 5)
                .padding(.top, Theme.Spacing.sm)

            Text("How was today?")
                .font(Theme.Typography.title())
                .foregroundStyle(Theme.Colors.textPrimary)
                .padding(.top, Theme.Spacing.sm)

            VStack(spacing: Theme.Spacing.sm) {
                SolidPillButton(title: "Clean 💪", fill: Theme.Colors.green,
                                textColor: Color(hex: 0x04170B)) { saveClean() }
                Button { showSlipLog = true } label: {
                    Text("I slipped")
                        .font(Theme.Typography.button())
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Theme.Colors.surface2, in: Capsule())
                }
                .buttonStyle(PressableButtonStyle())
            }

            TextField("Anything worth remembering about today? (optional)",
                      text: $note, axis: .vertical)
                .font(Theme.Typography.body())
                .foregroundStyle(Theme.Colors.textPrimary)
                .lineLimit(1...3)
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.surface2, in: RoundedRectangle(cornerRadius: Theme.Radius.md))

            Text("Three seconds. That's the whole ritual.")
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Colors.textTertiary)

            Spacer(minLength: 0)
        }
        .screenPadding()
        .padding(.bottom, Theme.Spacing.lg)
    }

    private var celebration: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.white, Theme.Colors.green)
                .transition(.scale(scale: 0.92).combined(with: .opacity))
            Text("Clean day logged 💪")
                .font(Theme.Typography.title())
                .foregroundStyle(Theme.Colors.textPrimary)
            Text("+5 gems · come back tomorrow to keep the run alive.")
                .font(Theme.Typography.body())
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)

            if !appState.reminderEnabled || reminderJustSet {
                Button {
                    guard !reminderJustSet else { return }
                    enableNightlyReminder()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: reminderJustSet ? "checkmark.circle.fill" : "bell.badge")
                        Text(reminderJustSet ? "Reminder set for 9 PM" : "Remind me tomorrow evening")
                    }
                    .font(Theme.Typography.bodyMedium())
                    .foregroundStyle(reminderJustSet ? Theme.Colors.green : Theme.Colors.textPrimary)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, 10)
                    .background(Theme.Colors.surface2, in: Capsule())
                }
                .buttonStyle(PressableButtonStyle())
                .animation(Theme.Motion.enter, value: reminderJustSet)
            }

            Spacer()
            PrimaryButton(title: "Done") { dismiss() }
                .screenPadding()
                .padding(.bottom, Theme.Spacing.lg)
        }
    }

    /// Request permission + schedule the 9 PM default. Full time control lives
    /// in Settings → Daily Reminders; this is the one-tap contextual version.
    private func enableNightlyReminder() {
        Task {
            let granted = await ReminderScheduler.requestPermission()
            guard granted else { return }
            appState.setReminder(enabled: true, hour: 21, minute: 0)
            ReminderScheduler.scheduleDaily(hour: 21, minute: 0)
            Haptics.success()
            reminderJustSet = true
        }
    }

    private func saveClean() {
        streak.saveReport(DailyReport(
            dayNumber: streak.currentRunDays + 1, date: Date(),
            watchedPorn: false, masturbated: false, relapsed: false, note: note))
        gems.award(5)
        Analytics.capture("checkin_clean")
        Haptics.success()
        savedClean = true
    }
}

#Preview {
    CheckInFlow()
        .environment(StreakStore())
        .environment(GemStore())
}
