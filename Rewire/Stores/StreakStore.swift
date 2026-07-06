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

    /// User tapped "Yes, relapsed" — bank the finished streak, update the record,
    /// and reset the timer.
    func relapse() {
        if elapsed > recordSeconds { recordSeconds = elapsed }
        let nextIndex = (streaks.map(\.index).max() ?? 0) + 1
        streaks.insert(Streak(index: nextIndex, duration: elapsed, isOngoing: false), at: 0)
        startDate = Date()
        elapsed = 0
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
    }
}
