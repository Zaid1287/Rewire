import SwiftUI
import UserNotifications

/// Reminder Notifications sheet (Quit Porn → Boost your progress). Two
/// independent reminders: the daily check-in at a time you pick, and the
/// motivation reminders that push your own "why" back at you through the day.
/// Mirrors MotivationsView's sheet chrome (drag capsule + title).
struct ReminderSettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var enabled = false
    @State private var time = Date()
    @State private var permissionDenied = false
    @State private var motivationsOn = false

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            SheetChrome(title: "Daily Reminder")

            VStack(spacing: Theme.Spacing.sm) {
                HStack {
                    Text("Remind me daily")
                        .font(Theme.Typography.body())
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Spacer()
                    Toggle("", isOn: $enabled)
                        .labelsHidden()
                        .tint(Theme.Colors.good)
                        .onChange(of: enabled) { _, newValue in toggleChanged(newValue) }
                }
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))

                if enabled {
                    HStack {
                        Text("Time")
                            .font(Theme.Typography.body())
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Spacer()
                        DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .colorScheme(.dark)
                            .onChange(of: time) { _, newValue in reschedule(newValue) }
                    }
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
                }

                motivationSection

                if permissionDenied {
                    VStack(spacing: Theme.Spacing.sm) {
                        Text("Notifications are disabled for Rewire")
                            .font(Theme.Typography.body())
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                        Button("Open Settings") {
                            Haptics.tap()
                            ReminderScheduler.openSystemSettings()
                        }
                        .font(Theme.Typography.body())
                        .foregroundStyle(Theme.Colors.good)
                    }
                    .padding(Theme.Spacing.md)
                    .frame(maxWidth: .infinity)
                    .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
                }
            }
            .screenPadding()

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background { SceneBackground(kind: .void) }
        .onAppear(perform: onAppear)
    }

    // MARK: Motivation reminders

    /// The differentiated half of this screen: their own words, back at them,
    /// at unpredictable times. Disabled until there's at least one motivation
    /// to send — an empty list would otherwise silently schedule nothing.
    @ViewBuilder private var motivationSection: some View {
        let hasMotivations = !appState.motivations.isEmpty

        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Remind me why")
                        .font(Theme.Typography.body())
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text(hasMotivations
                         ? "Your own motivations, at random times through the day."
                         : "Add a motivation first — these send your own words back to you.")
                        .font(Theme.Typography.caption())
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: Theme.Spacing.sm)
                Toggle("", isOn: $motivationsOn)
                    .labelsHidden()
                    .tint(Theme.Colors.good)
                    .disabled(!hasMotivations)
                    .onChange(of: motivationsOn) { _, newValue in motivationsToggled(newValue) }
            }

            if motivationsOn && hasMotivations {
                RowDivider(inset: 0)
                HStack {
                    Text("How many a day")
                        .font(Theme.Typography.body())
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Spacer()
                    // The count is its own Text: `.labelsHidden()` is what keeps
                    // the stepper from rendering a second, stretched label, and
                    // it would hide the number too if it lived inside.
                    Text("\(appState.motivationsPerDay)")
                        .font(Theme.Typography.bodyMedium())
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .monospacedDigit()
                        .padding(.trailing, Theme.Spacing.sm)
                    Stepper("Motivation reminders per day", value: Binding(
                        get: { appState.motivationsPerDay },
                        set: { appState.setMotivationReminders(enabled: true, perDay: $0) }
                    ), in: ReminderScheduler.motivationRange)
                    .labelsHidden()
                    .fixedSize()
                }
                Text("Between \(ReminderScheduler.motivationWindow.start):00 and \(ReminderScheduler.motivationWindow.end):00 — never overnight.")
                    .font(Theme.Typography.caption())
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
        .opacity(hasMotivations ? 1 : 0.6)
        .animation(Theme.Motion.enter, value: motivationsOn)
    }

    private func motivationsToggled(_ newValue: Bool) {
        Haptics.tap()
        guard newValue else {
            appState.setMotivationReminders(enabled: false)
            return
        }
        Task {
            let granted = await ReminderScheduler.requestPermission()
            if granted {
                permissionDenied = false
                appState.setMotivationReminders(enabled: true)
            } else {
                permissionDenied = true
                motivationsOn = false
            }
        }
    }

    private func onAppear() {
        enabled = appState.reminderEnabled
        motivationsOn = appState.motivationRemindersEnabled
        time = Calendar.current.date(
            bySettingHour: appState.reminderHour, minute: appState.reminderMinute, second: 0, of: Date()
        ) ?? Date()

        Task {
            let status = await ReminderScheduler.currentAuthStatus()
            guard status != .authorized else { return }
            // Permission was revoked in system Settings since it was last turned on.
            if appState.reminderEnabled {
                permissionDenied = true
                enabled = false
            }
            if appState.motivationRemindersEnabled {
                permissionDenied = true
                motivationsOn = false
                appState.setMotivationReminders(enabled: false)
            }
        }
    }

    private func toggleChanged(_ newValue: Bool) {
        Haptics.tap()
        if newValue {
            Task {
                let granted = await ReminderScheduler.requestPermission()
                if granted {
                    permissionDenied = false
                    let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
                    appState.setReminder(enabled: true, hour: comps.hour, minute: comps.minute)
                    ReminderScheduler.scheduleDaily(hour: comps.hour ?? 21, minute: comps.minute ?? 0)
                } else {
                    permissionDenied = true
                    enabled = false
                }
            }
        } else {
            permissionDenied = false
            appState.setReminder(enabled: false)
            ReminderScheduler.cancelAll()
        }
    }

    private func reschedule(_ newTime: Date) {
        guard enabled else { return }
        let comps = Calendar.current.dateComponents([.hour, .minute], from: newTime)
        appState.setReminder(enabled: true, hour: comps.hour, minute: comps.minute)
        ReminderScheduler.scheduleDaily(hour: comps.hour ?? 21, minute: comps.minute ?? 0)
    }
}

#Preview { ReminderSettingsView().environment(AppState()) }
