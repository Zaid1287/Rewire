import UIKit
import UserNotifications

/// Thin wrapper around `UNUserNotificationCenter` for the daily check-in
/// reminder and the motivation reminders. Pure I/O — no app state lives here;
/// callers (views) decide when to request permission and pass the result into
/// AppState.
enum ReminderScheduler {
    static let identifier = "daily-reminder"

    // MARK: Motivation reminders

    /// Hours the motivation reminders are allowed to fire between. Nothing
    /// pings someone at 3am — the window is the whole point of a fixed one.
    static let motivationWindow = (start: 9, end: 21)
    /// Days pre-scheduled ahead. Content differs per notification, so these
    /// can't be one repeating trigger — each is its own dated request, and the
    /// window rolls forward every time the app comes to the foreground.
    /// 7 × max 5/day = 35, comfortably under the iOS 64-pending cap.
    static let motivationDays = 7
    static let motivationRange = 1...5

    /// One planned motivation notification.
    struct MotivationSlot: Equatable {
        let id: String
        let body: String
        let date: Date
    }

    /// The pure half of the scheduler: what would be scheduled, without
    /// touching `UNUserNotificationCenter`. Split out so `selfCheck()` can
    /// assert on it — a competitor shipped literal "reminder body 1" strings
    /// to production and got reviewed for it.
    ///
    /// Slots are evenly spaced across the window then jittered, because the
    /// behaviour reviewers actually praise is "randomly through the day", not
    /// clockwork. Past slots for today are dropped.
    static func motivationPlan(texts: [String],
                               perDay: Int,
                               from now: Date = Date(),
                               calendar: Calendar = .current) -> [MotivationSlot] {
        let bodies = texts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !bodies.isEmpty else { return [] }

        let perDay = min(max(perDay, motivationRange.lowerBound), motivationRange.upperBound)
        let startMin = motivationWindow.start * 60
        let endMin = motivationWindow.end * 60
        let gap = (endMin - startMin) / perDay
        // Start the rotation somewhere random so the same "why" isn't forever
        // the 9am one.
        let offset = Int.random(in: 0..<bodies.count)

        var slots: [MotivationSlot] = []
        for day in 0..<motivationDays {
            guard let midnight = calendar.date(byAdding: .day, value: day,
                                               to: calendar.startOfDay(for: now)) else { continue }
            for i in 0..<perDay {
                let centre = startMin + gap * i + gap / 2
                let jitter = gap / 3
                let minute = min(max(centre + Int.random(in: -jitter...jitter), startMin), endMin)
                guard let fire = calendar.date(byAdding: .minute, value: minute, to: midnight),
                      fire > now else { continue }
                let body = bodies[(day * perDay + i + offset) % bodies.count]
                slots.append(MotivationSlot(id: "motivation-\(day)-\(i)", body: body, date: fire))
            }
        }
        return slots
    }

    /// Every id `motivationPlan` can ever produce — used to clear the previous
    /// batch without an async round-trip for pending requests.
    private static var allMotivationIDs: [String] {
        (0..<motivationDays).flatMap { day in
            motivationRange.map { "motivation-\(day)-\($0 - 1)" }
        }
    }

    /// Replaces the pre-scheduled motivation batch. Safe to call on every
    /// foreground — it clears the old batch first, so the 7-day window just
    /// rolls forward.
    static func scheduleMotivations(texts: [String], perDay: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: allMotivationIDs)

        for slot in motivationPlan(texts: texts, perDay: perDay) {
            let content = UNMutableNotificationContent()
            content.title = "Remember why"
            content.body = slot.body            // the user's own words, verbatim
            content.sound = .default

            let comps = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: slot.date
            )
            let request = UNNotificationRequest(
                identifier: slot.id,
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            )
            center.add(request)
        }
    }

    /// Cancels the motivation batch, leaving the daily check-in reminder alone.
    static func cancelMotivations() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: allMotivationIDs)
    }

    #if DEBUG
    /// Runs on debug launch alongside `StreakStore.selfCheck()`. Guards the
    /// things that would be invisible until a user complains: placeholder or
    /// empty bodies, notifications outside the window, and slots in the past.
    static func selfCheck() {
        let cal = Calendar.current
        let noon = cal.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!

        // Empty / whitespace-only input schedules nothing at all.
        assert(motivationPlan(texts: [], perDay: 3, from: noon).isEmpty)
        assert(motivationPlan(texts: ["", "   ", "\n"], perDay: 3, from: noon).isEmpty)

        let texts = ["For my daughter", "I want my focus back", "I'm done lying about it"]
        let plan = motivationPlan(texts: texts, perDay: 3, from: noon, calendar: cal)

        // Every body is one of the user's own, non-empty, never a placeholder.
        assert(!plan.isEmpty)
        assert(plan.allSatisfy { texts.contains($0.body) })
        assert(plan.allSatisfy { !$0.body.trimmingCharacters(in: .whitespaces).isEmpty })

        // Nothing fires outside the window, and nothing fires in the past.
        assert(plan.allSatisfy { slot in
            let h = cal.component(.hour, from: slot.date)
            return h >= motivationWindow.start && h <= motivationWindow.end
        })
        assert(plan.allSatisfy { $0.date > noon })

        // Ids are unique and all within the set we know how to cancel.
        assert(Set(plan.map(\.id)).count == plan.count)
        assert(plan.allSatisfy { allMotivationIDs.contains($0.id) })

        // A single motivation still fills every slot (rotation must not divide by zero).
        assert(motivationPlan(texts: ["one reason"], perDay: 5, from: noon)
            .allSatisfy { $0.body == "one reason" })

        // Say so, like the other four. A silent pass is indistinguishable from
        // a check that never ran.
        print("ReminderScheduler.selfCheck passed")

        // Out-of-range perDay is clamped, not trusted.
        let clamped = motivationPlan(texts: texts, perDay: 99, from: noon, calendar: cal)
        let perDayCounts = Dictionary(grouping: clamped, by: { $0.id.split(separator: "-")[1] })
        assert(perDayCounts.values.allSatisfy { $0.count <= motivationRange.upperBound })

        // Pending requests must stay under the iOS 64 cap, daily reminder included.
        assert(allMotivationIDs.count + 1 < 64)
    }
    #endif

    // MARK: Daily check-in reminder

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
