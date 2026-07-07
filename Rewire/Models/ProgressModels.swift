import Foundation

/// A recovery/no-nut streak record shown in History.
struct Streak: Identifiable, Codable {
    var id = UUID()
    let index: Int
    let duration: TimeInterval
    let isOngoing: Bool
}

/// A personal "why I quit" note (Quit Porn → My Motivations), surfaced again
/// in Panic Mode as a reminder of the user's own reasons.
struct Motivation: Identifiable, Codable {
    var id = UUID()
    var text: String
    var date: Date = Date()
}

/// A saved daily report entry (History → streak detail).
struct DailyReport: Identifiable, Codable {
    var id = UUID()
    let dayNumber: Int
    let date: Date
    /// P / M / O flags — Porn, Masturbation, Orgasm — highlighted when true.
    let watchedPorn: Bool
    let masturbated: Bool
    let relapsed: Bool
    let note: String
}

/// A goal option on the Set Goal screen.
struct Goal: Identifiable, Equatable, Codable {
    var id = UUID()
    let label: String
    let seconds: TimeInterval
}

/// A logged history event (History → Add Event).
struct StreakEvent: Identifiable, Codable {
    var id = UUID()
    var date: Date = Date()
    /// Event kind — matches the Add Event screen options.
    enum Kind: String, Codable, CaseIterable { case relapse, milestone, note }
    let type: Kind
    var note: String? = nil
}

/// One day cell in the weekly-challenge list (Home → challenge).
struct ChallengeDay: Identifiable, Codable {
    var id = UUID()
    let number: Int
    let dateLabel: String
    enum State: String, Codable { case pending, done, failed }
    var state: State
}

/// A calendar day marker on the My Streak sheet.
struct CalendarDay: Identifiable {
    let id = UUID()
    let day: Int
    let inMonth: Bool
    enum Marker { case none, today, flag, relapse }
    let marker: Marker
}
