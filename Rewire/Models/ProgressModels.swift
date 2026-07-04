import Foundation

/// A recovery/no-nut streak record shown in History.
struct Streak: Identifiable {
    let id = UUID()
    let index: Int
    let duration: TimeInterval
    let isOngoing: Bool
}

/// A saved daily report entry (History → streak detail).
struct DailyReport: Identifiable {
    let id = UUID()
    let dayNumber: Int
    let date: Date
    /// P / M / O flags — Porn, Masturbation, Orgasm — highlighted when true.
    let watchedPorn: Bool
    let masturbated: Bool
    let relapsed: Bool
    let note: String
}

/// A goal option on the Set Goal screen.
struct Goal: Identifiable, Equatable {
    let id = UUID()
    let label: String
    let seconds: TimeInterval
}

/// One day cell in the weekly-challenge list (Home → challenge).
struct ChallengeDay: Identifiable {
    let id = UUID()
    let number: Int
    let dateLabel: String
    enum State { case pending, done, failed }
    let state: State
}

/// A calendar day marker on the My Streak sheet.
struct CalendarDay: Identifiable {
    let id = UUID()
    let day: Int
    let inMonth: Bool
    enum Marker { case none, today, flag, relapse }
    let marker: Marker
}
