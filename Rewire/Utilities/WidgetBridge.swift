import Foundation
import WidgetKit

/// Publishes the few streak primitives the home/lock-screen widget needs into
/// the shared App Group, and nudges WidgetKit to redraw.
///
/// The widget is a separate target, so it can't see `StreakStore`. Rather than
/// share a compilation unit (and drag the whole model + its deps into an
/// extension), the app writes three plain numbers and the widget reads them by
/// key. The keys are duplicated in the widget by necessity — keep them in sync.
enum WidgetBridge {
    static let startKey = "widget.startEpoch"
    static let goalSecondsKey = "widget.goalSeconds"
    static let bestRunDaysKey = "widget.bestRunDays"

    static func publish(startDate: Date, goalSeconds: TimeInterval, bestRunDays: Int) {
        guard let defaults = UserDefaults(suiteName: ShieldEventStore.appGroup) else { return }
        defaults.set(startDate.timeIntervalSince1970, forKey: startKey)
        defaults.set(goalSeconds, forKey: goalSecondsKey)
        defaults.set(bestRunDays, forKey: bestRunDaysKey)
        // A counting-up streak needs no scheduled refreshes — the widget derives
        // elapsed from `startEpoch` locally. We only reload when the start moves
        // (relapse, backdate) or the record changes.
        WidgetCenter.shared.reloadAllTimelines()
    }
}
