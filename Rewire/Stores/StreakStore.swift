import SwiftUI
import Combine

/// Drives the live streak timer, current goal, progress, and saved reports.
/// The screenshots show a brand-new user (streak measured in seconds/minutes),
/// so the timer starts near zero and ticks up live.
@Observable
final class StreakStore {
    /// When the current streak began. Settable internally so `addDays` can shift it.
    private(set) var startDate: Date
    /// Selected goal (defaults to the "2 hours" option shown selected).
    var goal: Goal = SampleData.goals[0] { didSet { persist?() } }
    /// Best streak so far, for the "1 minute left to break your record" line.
    private(set) var recordSeconds: TimeInterval = 60 { didSet { persist?() } }

    private(set) var elapsed: TimeInterval = 57   // matches "57 seconds" first-victory shot
    private var timer: AnyCancellable?

    var reports: [DailyReport] = [] { didSet { persist?() } }
    var streaks: [Streak] = SampleData.streaks { didSet { persist?() } }

    /// History events (History → Add Event).
    private(set) var events: [StreakEvent] = [] { didSet { persist?() } }

    /// Weekly-challenge participation.
    private(set) var challengeJoined: Bool = false { didSet { persist?() } }
    private(set) var challengeDays: [ChallengeDay] = SampleData.challengeDays { didSet { persist?() } }

    /// 21-day Personal Plan — set of completed day numbers.
    private(set) var completedPlanDays: Set<Int> = [] { didSet { persist?() } }

    /// Saver injected by RewireApp so mutations flush to disk.
    var persist: (() -> Void)?

    init(startSecondsAgo: TimeInterval = 57) {
        startDate = Date().addingTimeInterval(-startSecondsAgo)
        elapsed = startSecondsAgo
        start()
    }

    func start() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.elapsed = Date().timeIntervalSince(self.startDate)
            }
    }

    /// Progress toward the current goal, 0…1.
    var progress: Double {
        guard goal.seconds > 0 else { return 0 }
        return min(1, elapsed / goal.seconds)
    }

    var progressPercentText: String {
        String(format: "%.2f%%", progress * 100)
    }

    var components: StreakComponents { elapsed.streakComponents }

    // MARK: Two-layer streak aggregation (flow-redesign Phase 1)
    // The redesign's core: a "record" layer that only ever grows, sitting above
    // the "current run" that resets on a slip. All derived from already-persisted
    // fields (streaks / elapsed / recordSeconds / events) — no new stored state,
    // no snapshot migration. Every banked run keeps counting toward the totals,
    // so a relapse subtracts from the *run*, never from the record.

    /// Current run length in whole days (the resettable layer).
    var currentRunDays: Int { Int(elapsed / 86_400) }

    /// Every completed run's clean time plus the live run, in whole days.
    /// Only grows: each relapse banks the finished run into `streaks`, which
    /// stays in this sum forever. `isOngoing` sample rows are excluded so the
    /// live run (counted via `elapsed`) isn't double-counted.
    var totalCleanDays: Int {
        let banked = streaks.filter { !$0.isOngoing }.reduce(0) { $0 + $1.duration }
        return Int((banked + elapsed) / 86_400)
    }

    /// Longest single run ever, in whole days.
    var bestRunDays: Int { Int(max(recordSeconds, elapsed) / 86_400) }

    /// Of the days elapsed so far this month (including today), the share with no
    /// logged relapse. 100% for a clean month or a user with no relapse history.
    var cleanThisMonthPercent: Int {
        let cal = Calendar.current
        let now = Date()
        let daysElapsed = cal.component(.day, from: now)   // 1…31, includes today
        guard daysElapsed > 0,
              let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: now))
        else { return 100 }
        let relapseDays = Set(
            events.filter { $0.type == .relapse && $0.date >= monthStart }
                  .map { cal.startOfDay(for: $0.date) }
        )
        let clean = max(0, daysElapsed - relapseDays.count)
        return Int((Double(clean) / Double(daysElapsed) * 100).rounded())
    }

    /// True once there's at least one whole clean day banked — drives the Home
    /// hero's "morning after a slip" framing (lead with what survived, not
    /// day 0). Whole days, not any banked row: the sample data seeds a 60s
    /// streak, and "Still 0." would be worse than the first-victory hero.
    var hasRecord: Bool { totalCleanDays > 0 }

    /// User tapped "Yes, relapsed" — bank the finished streak, update the record,
    /// and reset the timer.
    func relapse() {
        if elapsed > recordSeconds { recordSeconds = elapsed }
        let nextIndex = (streaks.map(\.index).max() ?? 0) + 1
        streaks.insert(Streak(index: nextIndex, duration: elapsed, isOngoing: false), at: 0)
        startDate = Date()
        elapsed = 0
    }

    // MARK: Slip Log (flow-redesign Phase 2)

    /// Record a slip: bank the finished run, capture pattern data, and reset the
    /// current run — but only when the user *saves* the Slip Log, never on entry,
    /// so backing out costs nothing. Returns the created event so the caller can
    /// offer an immediate undo on exactly it. Reverse with `undoSlip(_:)`.
    /// `source` is nil for the manual Slip Log, "shield" when auto-logged.
    /// `date` is when the slip *happened* — it defaults to now for the manual
    /// flow, but a shield slip is ingested whenever Rewire next opens, so the
    /// run it banks must end at the tap, not at the ingest.
    @discardableResult
    func logSlip(timeOfDay: String?, trigger: String?, feeling: String?,
                 source: String? = nil, at date: Date = Date()) -> StreakEvent {
        let preStart = startDate
        let preRecord = recordSeconds
        let runLength = max(0, date.timeIntervalSince(startDate))
        if runLength > recordSeconds { recordSeconds = runLength }

        let banked = Streak(index: (streaks.map(\.index).max() ?? 0) + 1,
                            duration: runLength, isOngoing: false)
        streaks.insert(banked, at: 0)

        let event = StreakEvent(date: date, type: .relapse,
                                timeOfDay: timeOfDay, trigger: trigger, feeling: feeling,
                                source: source,
                                bankedStreakID: banked.id,
                                preStartDate: preStart, preRecordSeconds: preRecord)
        events.insert(event, at: 0)

        startDate = date
        elapsed = Date().timeIntervalSince(date)
        return event
    }

    /// A shield "Not this time" tap. Deliberately touches no streak state — the
    /// run continues untouched; this is purely new data the manual flow can
    /// never produce.
    func logResisted(at date: Date = Date()) {
        events.insert(StreakEvent(date: date, type: .resisted, source: "shield"), at: 0)
    }

    /// Resisted urges logged, all-time. Survives a relapse on purpose: the count
    /// is the user's evidence they *can* say no, so a slip must not zero it.
    var resistedCount: Int { events.filter { $0.type == .resisted }.count }

    /// Drain shield-extension taps into the normal pipeline. Call on foreground.
    /// Relapses take the existing slip path, so undo-until-midnight and the
    /// two-layer totals keep working with no special-casing.
    func ingestShieldEvents() {
        let pending = ShieldEventStore.pending()
        guard !pending.isEmpty else { return }
        for event in pending.sorted(by: { $0.date < $1.date }) {
            switch event.kind {
            case .relapse:
                logSlip(timeOfDay: nil, trigger: nil, feeling: nil,
                        source: "shield", at: event.date)
            case .resisted:
                logResisted(at: event.date)
            }
        }
        // Clear only after the loop: every mutation above already flushed to
        // disk via `persist`, so a crash here re-ingests at worst nothing.
        ShieldEventStore.clear()
    }

    /// Reverse a slip: restore the run that was reset and drop the banked row +
    /// the event. No-op for non-slip or already-undone events.
    func undoSlip(_ event: StreakEvent) {
        guard event.type == .relapse else { return }
        if let start = event.preStartDate {
            startDate = start
            elapsed = Date().timeIntervalSince(start)
        }
        if let rec = event.preRecordSeconds { recordSeconds = rec }
        if let bankedID = event.bankedStreakID {
            streaks.removeAll { $0.id == bankedID }
        }
        events.removeAll { $0.id == event.id }
    }

    /// A slip stays undoable until midnight of the day it was logged (the
    /// forgiveness window for a misreport).
    func isSlipUndoable(_ event: StreakEvent) -> Bool {
        event.type == .relapse && Calendar.current.isDateInToday(event.date)
    }

    /// A one-line pattern read across recent slips, e.g. "3 of your last 4 slips
    /// were late-night." Nil when there isn't a clear dominant time-of-day yet.
    func slipPatternInsight() -> String? {
        let recent = events.filter { $0.type == .relapse }.prefix(4).compactMap(\.timeOfDay)
        guard recent.count >= 2 else { return nil }
        let counts = Dictionary(grouping: recent, by: { $0 }).mapValues(\.count)
        guard let (slot, n) = counts.max(by: { $0.value < $1.value }), n >= 2 else { return nil }
        return "\(n) of your last \(recent.count) slips were \(slot.lowercased())."
    }

    func setGoal(_ goal: Goal) { self.goal = goal }

    func saveReport(_ report: DailyReport) {
        reports.insert(report, at: 0)
    }

    // MARK: History events

    func addEvent(_ event: StreakEvent) {
        events.insert(event, at: 0)
    }

    func deleteStreak(_ streak: Streak) {
        streaks.removeAll { $0.id == streak.id }
    }

    /// Shift the streak start back `n` days (the "add days" cheat in the screenshots).
    func addDays(_ n: Int) {
        startDate -= TimeInterval(n * 86_400)
        elapsed = Date().timeIntervalSince(startDate)
        persist?()
    }

    // MARK: Weekly challenge

    func joinChallenge() { challengeJoined = true }

    /// Set the state of a challenge day by its number.
    func setChallengeDay(_ number: Int, to state: ChallengeDay.State) {
        guard let i = challengeDays.firstIndex(where: { $0.number == number }) else { return }
        challengeDays[i].state = state
    }

    // MARK: 21-day Personal Plan

    /// Toggle a plan day's completion. Any day can be toggled in any order.
    func togglePlanDay(_ day: Int) {
        if completedPlanDays.contains(day) {
            completedPlanDays.remove(day)
        } else {
            completedPlanDays.insert(day)
        }
    }

    // MARK: Persistence

    func restore(from s: AppSnapshot) {
        startDate = s.startDate
        elapsed = Date().timeIntervalSince(startDate)
        // SampleData.goals regenerates UUIDs each launch — re-match by label so
        // id-based selection (SetGoalView) still finds the current goal.
        goal = SampleData.goals.first { $0.label == s.goal.label } ?? s.goal
        recordSeconds = s.recordSeconds
        reports = s.reports
        streaks = s.streaks
        events = s.events
        challengeJoined = s.challengeJoined
        challengeDays = s.challengeDays
        completedPlanDays = s.completedPlanDays ?? []
    }
}
