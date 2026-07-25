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
    static let checkedInKey = "widget.checkedInToday"
    static let cleanDaysKey = "widget.cleanDays30"

    struct Snapshot {
        var start: Date
        var goal: TimeInterval
        var best: Int
        var checkedInToday: Bool
        /// Last 30 days oldest→newest, true = clean.
        var cleanDays: [Bool]
    }

    static func read() -> Snapshot? {
        guard let d = UserDefaults(suiteName: group),
              d.object(forKey: startKey) != nil else { return nil }
        let clean = (d.array(forKey: cleanDaysKey) as? [Int])?.map { $0 != 0 } ?? []
        return Snapshot(start: Date(timeIntervalSince1970: d.double(forKey: startKey)),
                        goal: d.double(forKey: goalSecondsKey),
                        best: d.integer(forKey: bestRunDaysKey),
                        checkedInToday: d.bool(forKey: checkedInKey),
                        cleanDays: clean)
    }
}

// MARK: Palette (RonLab literals — a widget target can't import the app's Theme)
// Home-screen tiles may use colour; the mockup's sanctioned vivid glance grid
// is one gradient per tile. Lock-screen accessories stay monochrome (§ views).

private extension Color {
    static let rwVoid = Color(red: 0x0A / 255, green: 0x0A / 255, blue: 0x0B / 255)
    static let rwInk = Color(red: 0xF6 / 255, green: 0xF7 / 255, blue: 0xF8 / 255)
    static let rwButter = Color(red: 0xE8 / 255, green: 0xC7 / 255, blue: 0x4B / 255)
    static let rwInkLo = Color.white.opacity(0.5)
    static func hex(_ v: UInt) -> Color {
        Color(red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255,
              blue: Double(v & 0xFF) / 255)
    }
}

/// The mockup's vivid tile gradients, one per glance widget.
private enum Tile {
    static let sage = LinearGradient(colors: [.hex(0x93B29B), .hex(0x465F52)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing)
    static let coral = LinearGradient(colors: [.hex(0xE9836F), .hex(0xB54468)],
                                      startPoint: .topLeading, endPoint: .bottomTrailing)
    static let ember = LinearGradient(colors: [.hex(0xC2402A), .hex(0x7A1F12)],
                                      startPoint: .topLeading, endPoint: .bottomTrailing)
    static let butter = LinearGradient(colors: [.hex(0xE8C74B), .hex(0xC79A2E)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
}

/// Morse-dash history strip — the §6 motif. Clean days are long dashes, relapse
/// days short red dots. Neutral tint given so it works on any tile.
private struct MorseStrip: View {
    var days: [Bool]
    var tint: Color = .white
    var body: some View {
        GeometryReader { geo in
            let recent = days.suffix(21)
            let gap: CGFloat = 3
            let w = (geo.size.width - gap * CGFloat(max(0, recent.count - 1))) / CGFloat(max(1, recent.count))
            HStack(spacing: gap) {
                ForEach(Array(recent.enumerated()), id: \.offset) { _, clean in
                    Capsule()
                        .fill(clean ? tint.opacity(0.9) : Color.hex(0xF5504E))
                        .frame(width: clean ? w : w * 0.55, height: clean ? 3 : 3)
                }
            }
            .frame(maxHeight: .infinity, alignment: .center)
        }
        .frame(height: 6)
    }
}

// MARK: Timeline

struct StreakEntry: TimelineEntry {
    let date: Date
    let start: Date
    let bestDays: Int
    /// nil when the app hasn't published yet (fresh install, widget added first).
    let hasData: Bool
    var checkedInToday: Bool = false
    var cleanDays: [Bool] = []

    var days: Int { max(0, Int(date.timeIntervalSince(start) / 86_400)) }
    var recoveryPercent: Int { min(100, days * 100 / 90) }   // 90-day rewire basis

    // Milestone the streak is climbing toward — gives the gauges something to
    // fill and turns a bare number into progress. Standard recovery marks.
    private static let milestones = [1, 3, 7, 14, 30, 60, 90, 180, 365]

    var nextMilestone: Int {
        Self.milestones.first { $0 > days } ?? ((days / 365) + 1) * 365
    }
    private var prevMilestone: Int {
        Self.milestones.last { $0 <= days } ?? 0
    }
    /// Fill within the current band (prev → next), so the ring moves meaningfully
    /// day to day instead of crawling from zero across a whole year.
    var milestoneProgress: Double {
        let span = Double(nextMilestone - prevMilestone)
        guard span > 0 else { return 1 }
        return min(1, max(0, Double(days - prevMilestone) / span))
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: Date(), start: Date().addingTimeInterval(-47 * 86_400),
                    bestDays: 61, hasData: true, checkedInToday: false,
                    cleanDays: (0..<30).map { $0 != 22 })
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
            return StreakEntry(date: Date(), start: s.start, bestDays: s.best, hasData: true,
                               checkedInToday: s.checkedInToday, cleanDays: s.cleanDays)
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
                if !entry.cleanDays.isEmpty {
                    MorseStrip(days: entry.cleanDays, tint: .rwInk)
                        .padding(.top, 6)
                }
            } else {
                Text("Open Rewire\nto start")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.rwInkLo)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) { Color.rwVoid }
    }

    // Lock-screen accessories are monochrome — the system tints them, so the
    // interest is form, not colour. The RonLab move is the instrument: a ticked
    // radial dial (Gauge renders it natively) filling toward the next milestone,
    // day count as the thin hero numeral in the centre.

    private var circular: some View {
        Group {
            if entry.hasData {
                Gauge(value: entry.milestoneProgress) {
                    Text("d")
                } currentValueLabel: {
                    Text("\(entry.days)").font(.system(size: 20, weight: .light))
                }
                .gaugeStyle(.accessoryCircular)
            } else {
                Image(systemName: "circle.dashed")
            }
        }
        .containerBackground(for: .widget) { Color.clear }
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                BrandDots(size: 11)
                Text("REWIRE").font(.system(size: 11, weight: .semibold)).opacity(0.6)
                Spacer(minLength: 0)
                if entry.hasData {
                    Text("→ \(entry.nextMilestone)d").font(.system(size: 11)).opacity(0.6)
                }
            }
            if entry.hasData {
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text("\(entry.days)").font(.system(size: 24, weight: .light))
                    Text(entry.days == 1 ? "day clean" : "days clean")
                        .font(.system(size: 13)).opacity(0.7)
                }
                // Ruler-style capacity gauge = the tick instrument, filling
                // toward the next milestone shown in the header.
                Gauge(value: entry.milestoneProgress) { EmptyView() }
                    .gaugeStyle(.accessoryLinearCapacity)
            } else {
                Text("Open Rewire to start").font(.system(size: 15, weight: .light))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(for: .widget) { Color.clear }
    }

    private var inline: some View {
        // Inline shows next to the clock — one glanceable line with a symbol.
        Label {
            Text(entry.hasData ? "\(entry.days)d clean · \(entry.nextMilestone)d next" : "Rewire")
        } icon: {
            Image(systemName: "flame")
        }
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

// MARK: Vivid glance tiles (home screen only — the mockup's sanctioned set)

/// Recovery — sage tile, 90-day rewire gauge. The mockup's Recovery glance.
struct RecoveryTileView: View {
    var entry: StreakEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("RECOVERY").font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7)).tracking(1)
            Spacer(minLength: 0)
            Gauge(value: Double(entry.recoveryPercent) / 100) {
                EmptyView()
            } currentValueLabel: {
                Text("\(entry.recoveryPercent)").font(.system(size: 30, weight: .thin))
                    .foregroundStyle(.white)
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(.white)
            .frame(maxWidth: .infinity, alignment: .center)
            Spacer(minLength: 0)
            Text("of 90-day rewire").font(.system(size: 11)).foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) { Tile.sage }
    }
}

/// Check-in — coral tile, 7 dots for the week (hollow = today, still pending).
/// The mockup's check-in glance; tapping opens Rewire to log.
struct CheckInTileView: View {
    var entry: StreakEntry
    private var week: [Bool] { Array(entry.cleanDays.suffix(7)) }
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("CHECK-IN").font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7)).tracking(1)
            Spacer(minLength: 0)
            Text(entry.checkedInToday ? "Done today" : "Tap to log")
                .font(.system(size: 20, weight: .light)).foregroundStyle(.white)
            HStack(spacing: 6) {
                ForEach(0..<7, id: \.self) { i in
                    let isToday = i == 6
                    Circle()
                        .strokeBorder(.white.opacity(0.9), lineWidth: 1.5)
                        .background(Circle().fill(
                            isToday && !entry.checkedInToday ? .clear : .white.opacity(0.9)))
                        .frame(width: 10, height: 10)
                }
            }
            Spacer(minLength: 0)
            Text("Honesty beats streaks").font(.system(size: 11)).foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) { Tile.coral }
    }
}

/// Urge SOS — ember tile, one job: tap to open Rewire's panic tool. The mockup
/// calls this out as the reason to have a home-screen widget at all — reach
/// beats any in-app entry in a crisis.
struct SOSTileView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Circle().fill(Color.hex(0xF5504E)).frame(width: 8, height: 8)
                Text("URGE SOS").font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85)).tracking(1)
            }
            Spacer(minLength: 0)
            Image(systemName: "wind").font(.system(size: 30, weight: .thin))
                .foregroundStyle(.white)
            Text("Tap to breathe").font(.system(size: 17, weight: .light)).foregroundStyle(.white)
            Spacer(minLength: 0)
            Text("This urge will pass").font(.system(size: 11)).foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) { Tile.ember }
    }
}

// MARK: Widget declarations

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

struct RewireRecoveryWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "RewireRecoveryWidget", provider: Provider()) { entry in
            RecoveryTileView(entry: entry)
        }
        .configurationDisplayName("Recovery")
        .description("How far into the 90-day rewiring window you are.")
        .supportedFamilies([.systemSmall])
    }
}

struct RewireCheckInWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "RewireCheckInWidget", provider: Provider()) { entry in
            CheckInTileView(entry: entry)
        }
        .configurationDisplayName("Check-in")
        .description("Your week at a glance — tap to log today.")
        .supportedFamilies([.systemSmall])
    }
}

struct RewireSOSWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "RewireSOSWidget", provider: Provider()) { _ in
            SOSTileView()
        }
        .configurationDisplayName("Urge SOS")
        .description("One tap to the panic tool when an urge hits.")
        .supportedFamilies([.systemSmall])
    }
}

@main
struct RewireWidgetBundle: WidgetBundle {
    var body: some Widget {
        RewireStreakWidget()
        RewireRecoveryWidget()
        RewireCheckInWidget()
        RewireSOSWidget()
    }
}
