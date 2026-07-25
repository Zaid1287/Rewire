import WidgetKit
import SwiftUI

// MARK: Shared data (App Group)

/// The widget is a separate target and can't see the app's `WidgetBridge`, so
/// the keys are duplicated here. Keep in sync with `WidgetBridge` in the app.
private enum Shared {
    static let group = "group.com.manimacha.rewire"
    static let startKey = "widget.startEpoch"
    static let goalSecondsKey = "widget.goalSeconds"
    static let bestRunDaysKey = "widget.bestRunDays"

    static func read() -> (start: Date, goal: TimeInterval, best: Int)? {
        guard let d = UserDefaults(suiteName: group),
              d.object(forKey: startKey) != nil else { return nil }
        return (Date(timeIntervalSince1970: d.double(forKey: startKey)),
                d.double(forKey: goalSecondsKey),
                d.integer(forKey: bestRunDaysKey))
    }
}

// MARK: Palette (RonLab literals — a widget target can't import the app's Theme)

private extension Color {
    static let rwVoid = Color(red: 0x0A / 255, green: 0x0A / 255, blue: 0x0B / 255)
    static let rwInk = Color(red: 0xF6 / 255, green: 0xF7 / 255, blue: 0xF8 / 255)
    static let rwButter = Color(red: 0xE8 / 255, green: 0xC7 / 255, blue: 0x4B / 255)
    static let rwInkLo = Color.white.opacity(0.5)
}

// MARK: Timeline

struct StreakEntry: TimelineEntry {
    let date: Date
    let start: Date
    let bestDays: Int
    /// nil when the app hasn't published yet (fresh install, widget added first).
    let hasData: Bool

    var days: Int { max(0, Int(date.timeIntervalSince(start) / 86_400)) }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: Date(), start: Date().addingTimeInterval(-4 * 86_400),
                    bestDays: 12, hasData: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        // A counting-up streak's day number only changes at midnight boundaries,
        // so refresh once a day rather than burning the widget's tight budget on
        // minute ticks. The app reloads us directly whenever the start moves.
        let entry = entry()
        let nextMidnight = Calendar.current.nextDate(
            after: Date(), matching: DateComponents(hour: 0, minute: 0),
            matchingPolicy: .nextTime) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }

    private func entry() -> StreakEntry {
        if let s = Shared.read() {
            return StreakEntry(date: Date(), start: s.start, bestDays: s.best, hasData: true)
        }
        return StreakEntry(date: Date(), start: Date(), bestDays: 0, hasData: false)
    }
}

// MARK: Views

struct RewireWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: StreakEntry

    var body: some View {
        switch family {
        case .accessoryInline:      inline
        case .accessoryCircular:    circular
        case .accessoryRectangular: rectangular
        default:                    home
        }
    }

    // Home / Lock-screen homescreen tiles (small + medium share the layout).
    private var home: some View {
        VStack(alignment: .leading, spacing: 2) {
            BrandDots(size: 16, color: .rwInk)
            Spacer(minLength: 0)
            if entry.hasData {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(entry.days)")
                        .font(.system(size: 46, weight: .thin))
                        .foregroundStyle(Color.rwInk)
                    Text(entry.days == 1 ? "day" : "days")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(Color.rwInkLo)
                }
                Text("clean streak")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.rwInkLo)
            } else {
                Text("Open Rewire\nto start")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.rwInkLo)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) { Color.rwVoid }
    }

    // Lock-screen accessories are monochrome — the system tints them.
    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("REWIRE").font(.system(size: 11, weight: .semibold)).opacity(0.7)
            Text(entry.hasData ? "\(entry.days) day\(entry.days == 1 ? "" : "s") clean" : "Open to start")
                .font(.system(size: 20, weight: .light))
            if entry.hasData {
                Text("best \(entry.bestDays)").font(.system(size: 12)).opacity(0.7)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(for: .widget) { Color.clear }
    }

    private var circular: some View {
        VStack(spacing: -2) {
            Text("\(entry.days)").font(.system(size: 22, weight: .light))
            Text("days").font(.system(size: 9))
        }
        .containerBackground(for: .widget) { Color.clear }
    }

    private var inline: some View {
        Text(entry.hasData ? "\(entry.days) days clean" : "Rewire")
            .containerBackground(for: .widget) { Color.clear }
    }
}

/// The 3-dot brand mark, redrawn here (the app's `BrandDots` lives in the app target).
struct BrandDots: View {
    var size: CGFloat = 16
    var color: Color = .white
    var body: some View {
        Canvas { ctx, _ in
            let s = size / 20
            for (x, y, r) in [(8.0, 7.0, 3.4), (14.4, 12.6, 2.1), (7.4, 14.6, 1.5)] {
                ctx.fill(Path(ellipseIn: CGRect(x: (x - r) * s, y: (y - r) * s,
                                                width: r * 2 * s, height: r * 2 * s)),
                         with: .color(color))
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: Widget declaration

struct RewireStreakWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "RewireStreakWidget", provider: Provider()) { entry in
            RewireWidgetView(entry: entry)
        }
        .configurationDisplayName("Streak")
        .description("Your current clean streak, on your home or lock screen.")
        .supportedFamilies([.systemSmall, .systemMedium,
                            .accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}

@main
struct RewireWidgetBundle: WidgetBundle {
    var body: some Widget { RewireStreakWidget() }
}
