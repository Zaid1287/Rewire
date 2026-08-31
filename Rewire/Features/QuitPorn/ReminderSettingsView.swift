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
                dailySection
                motivationSection
                if permissionDenied { permissionCard }
            }
            .screenPadding()

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background { SceneBackground(kind: .void) }
        .onAppear(perform: onAppear)
    }

    // MARK: Daily check-in reminder

    private var dailySection: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack {
                Text("Remind me daily")
                    .font(Theme.Typography.cardTitle())
                    .foregroundStyle(Theme.Colors.textHi)
                Spacer()
                GlassSwitch(isOn: $enabled)
                    .onChange(of: enabled) { _, newValue in toggleChanged(newValue) }
            }

            if enabled {
                RowDivider(inset: 0)
                HStack {
                    Text("Time:")
                        .font(Theme.Typography.label())
                        .foregroundStyle(Theme.Colors.textLo)
                    Spacer()
                    DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .colorScheme(.dark)
                        .onChange(of: time) { _, newValue in reschedule(newValue) }
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .smokedGlass(radius: Theme.Radius.glass)
        .animation(Theme.Motion.enter, value: enabled)
    }

    // MARK: Motivation reminders

    /// The differentiated half of this screen: their own words, back at them,
    /// at unpredictable times. Disabled until there's at least one motivation
    /// to send — an empty list would otherwise silently schedule nothing.
    ///
    /// Family A treatment: smoked glass over the Void scene, a butter glow
    /// behind the card once it's armed (the state tint is light behind the
    /// glass, never a tinted fill), and the frequency set on a tick ruler
    /// instead of a system stepper.
    @ViewBuilder private var motivationSection: some View {
        let hasMotivations = !appState.motivations.isEmpty
        let isArmed = motivationsOn && hasMotivations

        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Remind me why")
                        .font(Theme.Typography.cardTitle())
                        .foregroundStyle(Theme.Colors.textHi)
                    Text(hasMotivations
                         ? "Your own motivations, at random times through the day."
                         : "Add a motivation first — these send your own words back to you.")
                        .font(Theme.Typography.caption())
                        .foregroundStyle(Theme.Colors.textXlo)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: Theme.Spacing.sm)
                GlassSwitch(isOn: $motivationsOn, isEnabled: hasMotivations)
                    .onChange(of: motivationsOn) { _, newValue in motivationsToggled(newValue) }
            }

            if isArmed {
                RowDivider(inset: 0)

                Text("How often:")
                    .font(Theme.Typography.label())
                    .foregroundStyle(Theme.Colors.textLo)

                TickCountPicker(
                    value: Binding(
                        get: { appState.motivationsPerDay },
                        set: { appState.setMotivationReminders(enabled: true, perDay: $0) }
                    ),
                    range: ReminderScheduler.motivationRange,
                    unit: "a day")

                HStack(spacing: 6) {
                    Text("Window:")
                        .foregroundStyle(Theme.Colors.textLo)
                    Text("\(ReminderScheduler.motivationWindow.start):00 — \(ReminderScheduler.motivationWindow.end):00")
                        .foregroundStyle(Theme.Colors.textHi)
                    Text("· never overnight")
                        .foregroundStyle(Theme.Colors.textXlo)
                }
                .font(Theme.Typography.caption())
            }
        }
        .padding(Theme.Spacing.lg)
        // State tint = a glow that BLEEDS past one corner of the glass. A glow
        // sized to the card just washes the whole fill yellow through the
        // material, which is the tinted-fill anti-pattern wearing a blur.
        .background(alignment: .topTrailing) {
            Circle()
                .fill(Theme.Colors.butter)
                .frame(width: 150, height: 150)
                .blur(radius: 70)
                .offset(x: 60, y: -50)
                .opacity(isArmed ? 0.30 : 0)
                .allowsHitTesting(false)
        }
        .smokedGlass(radius: Theme.Radius.glass)
        .opacity(hasMotivations ? 1 : 0.55)
        .animation(Theme.Motion.enter, value: isArmed)
    }

    // MARK: Permission fallback

    private var permissionCard: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("Notifications are off for Rewire")
                .font(Theme.Typography.cardTitle())
                .foregroundStyle(Theme.Colors.textHi)
                .multilineTextAlignment(.center)
            Button("Open Settings") {
                Haptics.tap()
                ReminderScheduler.openSystemSettings()
            }
            .font(Theme.Typography.subtitle())
            .foregroundStyle(Theme.Colors.butter)
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity)
        .smokedGlass(radius: Theme.Radius.glass)
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
