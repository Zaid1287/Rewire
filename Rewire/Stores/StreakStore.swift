import SwiftUI
import Combine

/// Drives the live streak timer, current goal, progress, and saved reports.
/// The screenshots show a brand-new user (streak measured in seconds/minutes),
/// so the timer starts near zero and ticks up live.
@Observable
final class StreakStore {
    /// When the current streak began.
    private(set) var startDate: Date
    /// Selected goal (defaults to the "2 hours" option shown selected).
    var goal: Goal = SampleData.goals[0]
    /// Best streak so far, for the "1 minute left to break your record" line.
    var recordSeconds: TimeInterval = 60

    private(set) var elapsed: TimeInterval = 57   // matches "57 seconds" first-victory shot
    private var timer: AnyCancellable?

    var reports: [DailyReport] = []
    var streaks: [Streak] = SampleData.streaks

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

    /// User tapped "Yes, relapsed" — reset the timer.
    func relapse() {
        startDate = Date()
        elapsed = 0
    }

    func setGoal(_ goal: Goal) { self.goal = goal }

    func saveReport(_ report: DailyReport) {
        reports.insert(report, at: 0)
    }
}
