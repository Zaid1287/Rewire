import UIKit
import UserNotifications

/// Thin wrapper around `UNUserNotificationCenter` for the single daily
/// check-in reminder. Pure I/O — no app state lives here; callers (views)
/// decide when to request permission and pass the result into AppState.
enum ReminderScheduler {
    static let identifier = "daily-reminder"

    /// Prompts the system permission sheet. Returns whether alerts are granted.
    static func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    /// Replaces any existing daily reminder with one firing at `hour:minute`, every day.
    static func scheduleDaily(hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "Stay on track"
        content.body = "Check in with your streak today."
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }

    /// Cancels the daily reminder.
    static func cancelAll() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// Current notification permission status, without prompting.
    static func currentAuthStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    /// Deep-links to the app's page in system Settings.
    static func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
