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
            SceneBackground(kind: .fog)
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
            Capsule().fill(Theme.Colors.ink.opacity(0.2))
                .frame(width: 40, height: 5)
                .padding(.top, Theme.Spacing.sm)

            Text("Did you stay porn-free today?")
                .font(Theme.Typography.title())
                .foregroundStyle(Theme.Colors.ink)
                .multilineTextAlignment(.center)
                .padding(.top, Theme.Spacing.sm)

            VStack(spacing: Theme.Spacing.sm) {
                Button { saveClean() } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 15, weight: .medium))
                        Text("Yes, clean today")
                    }
                    .font(Theme.Typography.button())
                    .foregroundStyle(Color(hex: 0x141416))
                    .frame(maxWidth: .infinity)
                    .frame(height: 62)
                    .background(Color(hex: 0xF3F2EF), in: Capsule())
                    .shadow(color: .black.opacity(0.12), radius: 14, y: 6)
                }
                .buttonStyle(PressableButtonStyle())
                Button { showSlipLog = true } label: {
                    Text("Not today")
                        .font(Theme.Typography.button())
                        .foregroundStyle(Theme.Colors.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 62)
                        .background(Color.white.opacity(0.32), in: Capsule())
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.55), lineWidth: 1))
                }
                .buttonStyle(PressableButtonStyle())
            }

            TextField("Anything worth remembering about today? (optional)",
                      text: $note, axis: .vertical)
                .font(Theme.Typography.body())
                .foregroundStyle(Theme.Colors.ink)
                .lineLimit(1...3)
                .padding(Theme.Spacing.md)
                .background(Color.white.opacity(0.32), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            Text("Three seconds. Honesty beats streaks.")
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Colors.inkLo)

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
                .foregroundStyle(.white, Theme.Colors.good)
                .transition(.scale(scale: 0.92).combined(with: .opacity))
            Text("Clean day logged 💪")
                .font(Theme.Typography.title())
                .foregroundStyle(Theme.Colors.ink)
            Text("+5 gems · come back tomorrow to keep the run alive.")
                .font(Theme.Typography.body())
                .foregroundStyle(Theme.Colors.inkLo)
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
                    .foregroundStyle(reminderJustSet ? Theme.Colors.greenDark : Theme.Colors.ink)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.32), in: Capsule())
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
