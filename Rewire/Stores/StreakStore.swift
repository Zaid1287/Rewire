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

    /// Weekly-challenge participation. Joining is per week — `"2026-W34"` —
    /// so it's a commitment you renew, not a box you ticked once in July.
    private(set) var challengeWeek: String? = nil { didSet { persist?() } }
    /// Permanent: the Challenger badge shouldn't un-earn itself on Monday.
    private(set) var hasEverJoinedChallenge: Bool = false { didSet { persist?() } }

    var challengeJoined: Bool { challengeWeek == Self.weekKey(for: Date()) }

    /// This week's seven days, derived — nothing here is tappable or stored.
    var challengeDays: [ChallengeDay] {
        Self.weekDays(containing: Date(), relapseDays: relapseDayStarts)
    }

    /// Clean days out of *finished* days. Today is excluded from both sides
    /// while it's still running — counting a day you haven't finished as one
    /// you failed to keep clean would read as a deficit you can't be behind on.
    var challengeProgress: (clean: Int, finished: Int) {
        let days = challengeDays
        return (days.filter { $0.state == .done }.count,
                days.filter { $0.state == .done || $0.state == .failed }.count)
    }

    /// 21-day Personal Plan — set of completed day numbers.
    private(set) var completedPlanDays: Set<Int> = [] { didSet { persist?() } }

    /// Saver injected by RewireApp so mutations flush to disk.
    var persist: (() -> Void)?

    /// Push the streak primitives to the widget. Called only from the points
    /// where the start or the record actually move — never from the per-second
    /// `elapsed` tick, which would hammer WidgetCenter.
    func syncWidget() {
        WidgetBridge.publish(startDate: startDate,
                             goalSeconds: goal.seconds,
                             bestRunDays: bestRunDays,
                             checkedInToday: checkedInToday,
                             cleanDays30: cleanDays(30))
    }

    /// The days a relapse was logged on, normalised to midnight. The single
    /// definition of "was this day clean" — the Home strip, the widgets and the
    /// weekly challenge all answer from it, so they can never disagree.
    private var relapseDayStarts: Set<Date> {
        let cal = Calendar.current
        return Set(events.filter { $0.type == .relapse }.map { cal.startOfDay(for: $0.date) })
    }

    /// Last `n` days oldest→newest, true = no logged relapse that day. Same
    /// basis as the Home morse strip, exposed for the widgets.
    func cleanDays(_ n: Int) -> [Bool] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let relapseDays = relapseDayStarts
        return (0..<n).reversed().map { offset in
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { return true }
            return !relapseDays.contains(day)
        }
    }

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

    /// True once a clean check-in has been logged today. Gates the daily ritual
    /// so it can't be spammed for duplicate reports.
    var checkedInToday: Bool {
        reports.contains { !$0.relapsed && Calendar.current.isDateInToday($0.date) }
    }

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
        syncWidget()
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
        syncWidget()
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
            syncWidget()
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

    /// Set the current run's start to an exact instant.
    ///
    /// `addDays` can only shift back in whole days, so it can't fix "I actually
    /// started at 9pm three days ago", can't correct an over-add, and can't set
    /// the real start on first install. Those are the loudest concrete request
    /// in the tracking reviews — *"won't let me change my start day and time"*,
    /// *"just a counter and being able to adjust it for a date in the past"*.
    ///
    /// A future date is refused: the counter must never read negative, and
    /// "started tomorrow" is meaningless. Returns whether it took.
    @discardableResult
    func setStartDate(_ date: Date) -> Bool {
        guard date <= Date() else { return false }
        startDate = date
        elapsed = Date().timeIntervalSince(date)
        // `bestRunDays` already reads max(recordSeconds, elapsed), so a longer
        // backdated run shows up there without banking it into the permanent
        // record — banking an unfinished run early would leave the record
        // inflated after the next relapse.
        persist?()
        syncWidget()
        return true
    }

    // MARK: Weekly challenge

    func joinChallenge() {
        challengeWeek = Self.weekKey(for: Date())
        hasEverJoinedChallenge = true
    }

    /// `"2026-W34"` — the ISO-ish week a date falls in. Uses
    /// `yearForWeekOfYear` so the last days of December land in the right week.
    static func weekKey(for date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: date)
        return "\(c.yearForWeekOfYear ?? 0)-W\(c.weekOfYear ?? 0)"
    }

    /// The seven days of the week containing `date`. A day is failed if a slip
    /// was logged on it, done once it's over without one, today while it's
    /// still running, and upcoming before it arrives — so a week can never show
    /// a failure the user hasn't had, and future days are never pre-marked.
    static func weekDays(containing date: Date,
                         relapseDays: Set<Date>,
                         calendar: Calendar = .current) -> [ChallengeDay] {
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start
        else { return [] }
        let today = calendar.startOfDay(for: date)
        return (0..<7).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: weekStart)
            else { return nil }
            let state: ChallengeDay.State
            if relapseDays.contains(day)  { state = .failed }
            else if day > today           { state = .upcoming }
            else if day == today          { state = .today }
            else                          { state = .done }
            return ChallengeDay(number: offset + 1, date: day, state: state)
        }
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
        challengeWeek = s.challengeWeek
        // Pre-weekly snapshots only knew a permanent bool; carry it into the
        // badge flag so nobody loses a Challenger badge they earned.
        hasEverJoinedChallenge = s.hasEverJoinedChallenge ?? s.challengeJoined ?? false
        completedPlanDays = s.completedPlanDays ?? []
    }

    #if DEBUG
    /// The start-date editor is a streak-critical path with a real guard; the
    /// project has no test target, so it checks itself on debug launch.
    static func selfCheck() {
        let s = StreakStore()
        let record = s.recordSeconds

        // Future start is refused and changes nothing.
        let before = s.startDate
        precondition(s.setStartDate(Date().addingTimeInterval(3600)) == false)
        precondition(s.startDate == before, "a refused edit must not move the start")

        // Backdating three days is accepted and the counter follows.
        let threeDaysAgo = Date().addingTimeInterval(-3 * 86_400)
        precondition(s.setStartDate(threeDaysAgo) == true)
        precondition(Int(s.elapsed / 86_400) == 3, "elapsed should read 3 days")

        // A long backdated run shows in bestRunDays without banking into the
        // permanent record — the record only moves on a real relapse.
        precondition(s.bestRunDays >= 3)
        precondition(s.recordSeconds == record, "setStartDate must not touch the record")
        // Weekly challenge: derived from the record, so it must never invent a
        // failure or pre-mark a day that hasn't happened.
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 1
        let now = Date()
        let today = cal.startOfDay(for: now)
        let week = weekDays(containing: now, relapseDays: [], calendar: cal)
        precondition(week.count == 7)
        precondition(week.allSatisfy { $0.state != .failed },
                     "a clean record must never render a failed day")
        precondition(week.filter { $0.state == .today }.count == 1)
        precondition(!week.contains { $0.state == .done && $0.date >= today },
                     "today and later can never already be done")
        precondition(!week.contains { $0.state == .upcoming && $0.date <= today },
                     "a day that has arrived is not upcoming")
        // A slip logged today marks today, not some other day.
        let slipped = weekDays(containing: now, relapseDays: [today], calendar: cal)
        precondition(slipped.filter { $0.state == .failed }.map(\.date) == [today])
        // Joining is per week: the key moves when the week does.
        precondition(weekKey(for: now, calendar: cal)
                     != weekKey(for: now.addingTimeInterval(7 * 86_400), calendar: cal))

        print("StreakStore.selfCheck passed")
    }
    #endif
}
