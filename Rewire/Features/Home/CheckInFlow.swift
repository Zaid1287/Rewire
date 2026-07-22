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
                if savedClean { celebration }
                else if streak.checkedInToday { alreadyLogged }
                else { ask }
            }
            .transition(.opacity)
        }
        .animation(Theme.Motion.enter, value: savedClean)
        // A slip is a full-screen moment; on its dismiss, close the check-in too.
        .fullScreenCover(isPresented: $showSlipLog, onDismiss: { dismiss() }) {
            SlipLogFlow()
        }
    }

    /// How far into today we are — what the tick ruler reads. The mockup's
    /// ruler tracked "step 1 of 4" of a four-screen flow; this is one screen,
    /// so it carries the day's own progress instead of faking flow steps.
    /// (Goal progress was the other candidate and is wrong: a 2-hour goal
    /// against a 14-day run pins to 1.0 and draws a solid bar.)
    private var dayProgress: Double {
        let start = Calendar.current.startOfDay(for: Date())
        return min(1, Date().timeIntervalSince(start) / 86_400)
    }

    private var ask: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule().fill(Theme.Colors.ink.opacity(0.2))
                .frame(width: 40, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, Theme.Spacing.sm)

            // check-top: today's date left, run position right
            HStack {
                Text(Date(), format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                Spacer()
                Text("Check-in · ") + Text("Day \(streak.currentRunDays + 1)")
                    .foregroundStyle(Theme.Colors.ink)
            }
            .font(Theme.Typography.label())
            .foregroundStyle(Theme.Colors.inkLo)
            .padding(.top, Theme.Spacing.lg)

            TickRuler(progress: dayProgress)
                .padding(.top, Theme.Spacing.md)

            // milk-glass question card
            VStack(alignment: .leading, spacing: 0) {
                Text("Daily check-in")
                    .font(Theme.Typography.caption())
                    .tracking(1.3)
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.Colors.inkLo)
                Text("Did you stay porn-free today?")
                    .font(Theme.Typography.title())
                    .foregroundStyle(Theme.Colors.ink)
                    .padding(.top, Theme.Spacing.sm)
                (Text("Goal: ") + Text(streak.goal.label).foregroundStyle(Theme.Colors.ink)
                    + Text(" · answering keeps your history honest"))
                    .font(Theme.Typography.label())
                    .foregroundStyle(Theme.Colors.inkLo)
                    .padding(.top, Theme.Spacing.md)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 30)
            .frame(maxWidth: .infinity, alignment: .leading)
            .milkGlass(radius: 32)
            .padding(.top, Theme.Spacing.lg)

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
            .padding(.top, Theme.Spacing.lg)

            // Not in the mockup frame (that flow spread the note over later
            // steps), but it feeds DailyReport.note — kept, toned to the scene.
            TextField("", text: $note,
                      prompt: Text("Anything worth remembering about today?")
                        .foregroundColor(Theme.Colors.inkLo),
                      axis: .vertical)
                .font(Theme.Typography.body())
                .foregroundStyle(Theme.Colors.ink)
                .lineLimit(1...3)
                .padding(Theme.Spacing.md)
                .background(Color.white.opacity(0.32), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(.top, Theme.Spacing.md)

            Text("Three seconds. Honesty beats streaks.")
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Colors.inkLo)
                .frame(maxWidth: .infinity)
                .padding(.top, Theme.Spacing.md)

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

    /// Shown when today's check-in is already done — no second award, no
    /// duplicate report. Honest state instead of a repeatable +5.
    private var alreadyLogged: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.white, Theme.Colors.good)
            Text("Already logged today ✓")
                .font(Theme.Typography.title())
                .foregroundStyle(Theme.Colors.ink)
            Text("You're checked in. See you tomorrow.")
                .font(Theme.Typography.body())
                .foregroundStyle(Theme.Colors.inkLo)
                .multilineTextAlignment(.center)
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
        // Guard the award path: if today's already logged, just show the
        // celebration without a second +5 / duplicate report.
        guard !streak.checkedInToday else { savedClean = true; return }
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
