import Foundation

/// Breaks a streak duration into calendar-ish components for the live timer grid.
struct StreakComponents {
    let year: Int
    let month: Int
    let day: Int
    let hour: Int
    let minute: Int
    let second: Int

    /// Naive breakdown (30-day months, 365-day years) — matches the app's
    /// "Live Timer" tiles which are motivational, not calendar-exact.
    // ponytail: naive month=30/year=365; swap for Calendar.dateComponents if exactness ever matters.
    init(_ interval: TimeInterval) {
        var s = Int(max(0, interval))
        year = s / 31_536_000; s %= 31_536_000
        month = s / 2_592_000; s %= 2_592_000
        day = s / 86_400;      s %= 86_400
        hour = s / 3_600;      s %= 3_600
        minute = s / 60
        second = s % 60
    }
}

extension TimeInterval {
    var streakComponents: StreakComponents { StreakComponents(self) }

    /// "57 seconds", "1 minute", "3 hours" — largest non-zero unit, matching the
    /// pill/summary text used across Home and History.
    func humanShort() -> String {
        let c = StreakComponents(self)
        func unit(_ n: Int, _ s: String) -> String { "\(n) \(s)\(n == 1 ? "" : "s")" }
        if c.year > 0 { return unit(c.year, "year") }
        if c.month > 0 { return unit(c.month, "month") }
        if c.day > 0 { return unit(c.day, "day") }
        if c.hour > 0 { return unit(c.hour, "hour") }
        if c.minute > 0 { return unit(c.minute, "minute") }
        return unit(c.second, "second")
    }
}

enum RewireDate {
    static let full: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d, yyyy"
        return f
    }()

    static let monthYear: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    static let weekdayDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f
    }()
}
