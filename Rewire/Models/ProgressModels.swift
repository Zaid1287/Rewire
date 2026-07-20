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

/// A daily photo journal entry (Quit Porn → Appearance Tracker). The image
/// lives at Documents/appearance/<filename> — only the filename is persisted.
struct AppearancePhoto: Identifiable, Codable {
    var id = UUID()
    var date = Date()
    var filename: String
}

/// A logged history event (History → Add Event, and the Slip Log).
struct StreakEvent: Identifiable, Codable {
    var id = UUID()
    var date: Date = Date()
    /// Event kind — `relapse` / `milestone` / `note` match the Add Event screen
    /// options; `resisted` is shield-only (a "Not this time" tap) and never
    /// offered manually.
    enum Kind: String, Codable, CaseIterable { case relapse, milestone, note, resisted }
    let type: Kind
    var note: String? = nil

    // MARK: Slip-log pattern data (flow-redesign Phase 2)
    // Recorded on a `.relapse` event by the Slip Log. All optional so events
    // written before these fields existed (and non-slip events) still decode.
    /// When the slip happened — "Morning" / "Afternoon" / "Evening" / "Late night".
    var timeOfDay: String? = nil
    var trigger: String? = nil
    var feeling: String? = nil

    /// Where the event came from — nil for the manual flows, "shield" when a
    /// Screen Time shield tap auto-logged it. Optional like the fields above so
    /// pre-shield snapshots still decode.
    var source: String? = nil

    // MARK: Undo bookkeeping (flow-redesign Phase 2)
    // Enough state to reverse the streak reset a slip caused, until midnight.
    /// The `Streak` row this slip banked, so undo can remove exactly it.
    var bankedStreakID: UUID? = nil
    /// `startDate` before the reset — undo restores it so the run continues.
    var preStartDate: Date? = nil
    /// `recordSeconds` before the slip possibly bumped it — undo restores it.
    var preRecordSeconds: TimeInterval? = nil
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
