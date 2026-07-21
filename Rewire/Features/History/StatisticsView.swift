import SwiftUI

/// Stats tab — the app's one Family B screen (RonLab Ivory): warm paper ground,
/// opaque cards, display headline, and instrument viz (fan gauge, dot-matrix
/// score, barcode, morse) instead of charts. Reached from the dock.
struct StatisticsView: View {
    @Environment(StreakStore.self) private var streak

    /// Window the whole screen is scoped to.
    enum Range: String, CaseIterable, Identifiable {
        case week = "Week", month = "Month", all = "All time"
        var id: String { rawValue }
        /// Days of history the cards read; nil = everything.
        var days: Int? {
            switch self {
            case .week: 7
            case .month: 30
            case .all: nil
            }
        }
        /// How many marks/bars the micro-charts draw.
        var sampleCount: Int { days ?? 60 }
    }

    @State private var range: Range = .all

    // MARK: Derived data

    private var cal: Calendar { Calendar.current }
    private var today: Date { cal.startOfDay(for: Date()) }

    private var windowStart: Date? {
        guard let days = range.days else { return nil }
        return cal.date(byAdding: .day, value: -(days - 1), to: today)
    }

    private var reportDays: Set<Date> {
        Set(streak.reports.map { cal.startOfDay(for: $0.date) })
    }
    private var relapseDays: Set<Date> {
        Set(streak.events.filter { $0.type == .relapse }.map { cal.startOfDay(for: $0.date) })
    }

    /// Clean check-ins inside the window.
    private var cleanDaysCount: Int {
        streak.reports.filter { report in
            guard !report.watchedPorn, !report.masturbated, !report.relapsed else { return false }
            guard let start = windowStart else { return true }
            return cal.startOfDay(for: report.date) >= start
        }.count
    }

    /// Urges beaten = panic sessions ridden out, approximated by logged events
    /// that aren't relapses inside the window.
    private var urgesBeaten: Int {
        streak.events.filter { event in
            guard event.type != .relapse else { return false }
            guard let start = windowStart else { return true }
            return cal.startOfDay(for: event.date) >= start
        }.count
    }

    private var relapsesInWindow: Int {
        relapseDays.filter { day in
            guard let start = windowStart else { return true }
            return day >= start
        }.count
    }

    /// Mean length of finished streaks; falls back to the live streak.
    private var averageStreak: TimeInterval {
        let done = streak.streaks.filter { !$0.isOngoing }
        guard !done.isEmpty else { return streak.elapsed }
        return done.map(\.duration).reduce(0, +) / Double(done.count)
    }

    /// All finished streak time plus the ongoing one, in whole days.
    private var totalDays: Int {
        let total = streak.streaks.filter { !$0.isOngoing }.map(\.duration).reduce(0, +) + streak.elapsed
        return Int(total / 86_400)
    }

    /// Recovery score: clean days into the 90-day rewire window.
    private var score: Int { min(90, totalDays) }

    /// Day-by-day history for the window, oldest → newest.
    private func dayStates() -> [Bool?] {
        (0..<range.sampleCount).reversed().map { off in
            guard let d = cal.date(byAdding: .day, value: -off, to: today) else { return nil }
            if relapseDays.contains(d) { return false }
            return reportDays.contains(d) ? true : nil
        }
    }

    private var barcodeValues: [Double] {
        dayStates().map { state in
            switch state {
            case true?: 0.9
            case false?: 0.45
            default: 0.25
            }
        }
    }

    private var checkinMarks: [MorseMark] { MorseStrip.marks(fromDays: dayStates()) }

    // MARK: Body

    var body: some View {
        ZStack {
            SceneBackground(kind: .ivory)
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    header
                    filters
                    scoreCard
                    statPair
                    checkinsCard
                }
                .screenPadding()
                .padding(.top, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.tabBarClearance)
            }
            .collapsesDock()
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack(alignment: .top) {
            // Display headline — the one place SemiBold is allowed. Two Texts
            // with negative spacing: tight leading (~1.05) is the Family B look.
            VStack(alignment: .leading, spacing: -6) {
                Text("Your")
                Text("Recovery")
            }
            .font(Theme.Typography.displayHeadline())
            .foregroundStyle(Theme.Colors.ink)
            Spacer()
            ShareLink(item: shareSummary) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Theme.Colors.ink)
                    .frame(width: 44, height: 44)
                    .background(Theme.Colors.ink.opacity(0.05), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, 2)
    }

    private var shareSummary: String {
        "\(score) of 90 days rewired · \(cleanDaysCount) clean check-ins · Rewire"
    }

    private var filters: some View {
        HStack(spacing: 8) {
            ForEach(Range.allCases) { option in
                let on = option == range
                Button {
                    Haptics.select()
                    withAnimation(Theme.Motion.quick) { range = option }
                } label: {
                    Text(option.rawValue)
                        .font(Theme.Typography.subtitle())
                        .foregroundStyle(on ? Theme.Colors.ivoryCard : Theme.Colors.inkLo)
                        .padding(.horizontal, 18)
                        .frame(height: 38)
                        .background(on ? Theme.Colors.ink : Theme.Colors.ink.opacity(0.05),
                                    in: Capsule())
                }
                .buttonStyle(PressableButtonStyle())
            }
            Spacer(minLength: 0)
        }
        .padding(.bottom, 4)
    }

    private var scoreCard: some View {
        ivoryCard {
            VStack(alignment: .leading, spacing: 4) {
                Text("Recovery score")
                    .font(Theme.Typography.label())
                    .foregroundStyle(Theme.Colors.inkLo)
                HStack(alignment: .center) {
                    FanGauge(value: Double(score) / 90)
                        .frame(width: 170, height: 104)
                    Spacer(minLength: 0)
                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        DotMatrixNumeral(text: String(format: "%02d", score))
                        Text("/ 90")
                            .font(Theme.Typography.label())
                            .foregroundStyle(Theme.Colors.inkLo)
                    }
                }
                Text("Neural pathways weaken after ~90 clean days")
                    .font(Theme.Typography.caption())
                    .foregroundStyle(Theme.Colors.ink.opacity(0.45))
            }
        }
    }

    private var statPair: some View {
        HStack(spacing: 12) {
            ivoryCard {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Clean days")
                        .font(Theme.Typography.label())
                        .foregroundStyle(Theme.Colors.inkLo)
                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Text("\(cleanDaysCount)")
                            .font(Theme.Typography.unitSuffix(34))
                            .foregroundStyle(Theme.Colors.ink)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        Text("of \(range.sampleCount)")
                            .font(Theme.Typography.caption())
                            .foregroundStyle(Theme.Colors.inkLo)
                    }
                    BarcodeChart(values: barcodeValues,
                                 barColor: Theme.Colors.ink.opacity(0.22))
                        .frame(height: 26)
                        .padding(.top, 6)
                }
            }
            ivoryCard {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Urges beaten")
                        .font(Theme.Typography.label())
                        .foregroundStyle(Theme.Colors.inkLo)
                    Text("\(urgesBeaten)")
                        .font(Theme.Typography.unitSuffix(34))
                        .foregroundStyle(Theme.Colors.ink)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    StatusLabel(color: relapsesInWindow == 0 ? Theme.Colors.good : Theme.Colors.critical,
                                text: relapsesInWindow == 0 ? "Good"
                                    : "\(relapsesInWindow) relapse\(relapsesInWindow == 1 ? "" : "s")",
                                textColor: Theme.Colors.inkLo)
                        .padding(.top, 12)
                }
            }
        }
    }

    private var checkinsCard: some View {
        ivoryCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Check-ins · last \(range.sampleCount) days")
                    .font(Theme.Typography.label())
                    .foregroundStyle(Theme.Colors.inkLo)
                MorseStrip(marks: checkinMarks,
                           color: Theme.Colors.ink.opacity(0.7), fade: false)
                legend
            }
        }
    }

    private var legend: Text {
        Text("● ").foregroundStyle(Theme.Colors.good)
        + Text("clean · ").foregroundStyle(Theme.Colors.ink.opacity(0.45))
        + Text("● ").foregroundStyle(Theme.Colors.critical)
        + Text("relapse · dash = clean run")
            .foregroundStyle(Theme.Colors.ink.opacity(0.45))
    }

    private func ivoryCard(@ViewBuilder _ content: () -> some View) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Theme.Colors.ivoryCard,
                        in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .shadow(color: Theme.Colors.ink.opacity(0.07), radius: 16, y: 8)
    }
}

/// Streak detail (reached from a Recovery streak row). Void scene, glass cards.
struct StreakDetailView: View {
    let index: Int
    @Environment(StreakStore.self) private var streak
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            SceneBackground(kind: .void)
            VStack(spacing: 0) {
                NavHeader(title: "Streak #\(index)", showsBack: true, onBack: { dismiss() })
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Duration:")
                                .font(Theme.Typography.label())
                                .foregroundStyle(Theme.Colors.textLo)
                            Text({
                                guard let s = streak.streaks.first(where: { $0.index == index }) else {
                                    return TimeInterval(60).humanShort()
                                }
                                return (s.isOngoing ? streak.elapsed : s.duration).humanShort()
                            }())
                                .font(Theme.Typography.unitSuffix(34))
                                .foregroundStyle(Theme.Colors.textHi)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .smokedGlass(radius: 26)

                        Text("Daily reports").sectionHeaderStyle()
                        if streak.reports.isEmpty {
                            Text("No reports saved for this streak yet.")
                                .font(Theme.Typography.body())
                                .foregroundStyle(Theme.Colors.textLo)
                        } else {
                            ForEach(streak.reports) { report in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Day \(report.dayNumber) · \(RewireDate.full.string(from: report.date))")
                                        .font(Theme.Typography.label())
                                        .foregroundStyle(Theme.Colors.textLo)
                                    Text(report.note.isEmpty ? "—" : report.note)
                                        .font(Theme.Typography.body())
                                        .foregroundStyle(Theme.Colors.textHi)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(18)
                                .smokedGlass(radius: 22)
                            }
                        }
                    }
                    .screenPadding()
                    .padding(.top, Theme.Spacing.lg)
                    .padding(.bottom, Theme.Spacing.tabBarClearance)
                }
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
    }
}
