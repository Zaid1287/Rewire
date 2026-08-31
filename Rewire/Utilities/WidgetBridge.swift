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
    static let checkedInKey = "widget.checkedInToday"
    /// Last 30 days, oldest→newest, true = clean. Drives the morse strip on the
    /// streak/dashboard tiles and the week dots on the check-in tile.
    static let cleanDaysKey = "widget.cleanDays30"

    static func publish(startDate: Date, goalSeconds: TimeInterval, bestRunDays: Int,
                        checkedInToday: Bool, cleanDays30: [Bool]) {
        guard let defaults = UserDefaults(suiteName: ShieldEventStore.appGroup) else { return }
        defaults.set(startDate.timeIntervalSince1970, forKey: startKey)
        defaults.set(goalSeconds, forKey: goalSecondsKey)
        defaults.set(bestRunDays, forKey: bestRunDaysKey)
        defaults.set(checkedInToday, forKey: checkedInKey)
        defaults.set(cleanDays30.map { $0 ? 1 : 0 }, forKey: cleanDaysKey)
        // A counting-up streak needs no scheduled refreshes — the widget derives
        // elapsed from `startEpoch` locally. We only reload when the start moves
        // (relapse, backdate) or the record changes.
        WidgetCenter.shared.reloadAllTimelines()
    }
}
