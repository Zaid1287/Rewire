import SwiftUI
import UserNotifications

/// Reminder Notifications sheet (Quit Porn → Boost your progress). Toggle
/// on/off the daily local notification, and pick its time. Mirrors
/// MotivationsView's sheet chrome (drag capsule + title).
struct ReminderSettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var enabled = false
    @State private var time = Date()
    @State private var permissionDenied = false

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

    private func onAppear() {
        enabled = appState.reminderEnabled
        time = Calendar.current.date(
            bySettingHour: appState.reminderHour, minute: appState.reminderMinute, second: 0, of: Date()
        ) ?? Date()

        Task {
            let status = await ReminderScheduler.currentAuthStatus()
            if appState.reminderEnabled && status != .authorized {
                // Permission was revoked in system Settings since it was last turned on.
                permissionDenied = true
                enabled = false
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
