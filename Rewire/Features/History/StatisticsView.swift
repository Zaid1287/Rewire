import SwiftUI

/// Statistics — the app's one Family B screen (RonLab Ivory): warm paper ground,
/// opaque cards, display headline, and instrument viz (fan gauge, dot-matrix
/// score, barcode, morse) instead of charts.
struct StatisticsView: View {
    @Environment(StreakStore.self) private var streak
    @Environment(\.dismiss) private var dismiss

    /// Reports with no P/M/O flags — fully clean days.
    private var cleanDaysCount: Int {
        streak.reports.filter { !$0.watchedPorn && !$0.masturbated && !$0.relapsed }.count
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

    /// Last-30-days report rhythm for the barcode (days with a report stand tall).
    private var barcodeValues: [Double] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let reportDays = Set(streak.reports.map { cal.startOfDay(for: $0.date) })
        return (0..<30).reversed().map { off in
            guard let d = cal.date(byAdding: .day, value: -off, to: today) else { return 0.25 }
            return reportDays.contains(d) ? 0.9 : 0.25
        }
    }

    /// Check-in morse: report days as rhythm, relapses as red dots.
    private var checkinMarks: [MorseMark] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let reportDays = Set(streak.reports.map { cal.startOfDay(for: $0.date) })
        let relapseDays = Set(streak.events.filter { $0.type == .relapse }
            .map { cal.startOfDay(for: $0.date) })
        let days: [Bool?] = (0..<30).reversed().map { off in
            guard let d = cal.date(byAdding: .day, value: -off, to: today) else { return nil }
            if relapseDays.contains(d) { return false }
            return reportDays.contains(d) ? true : nil
        }
        return MorseStrip.marks(fromDays: days)
    }

    var body: some View {
        ZStack {
            SceneBackground(kind: .ivory)
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    header
                    scoreCard
                    statPair
                    checkinsCard
                }
                .screenPadding()
                .padding(.top, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.tabBarClearance)
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: Sections

    private var header: some View {
        HStack(alignment: .top) {
            // Display headline — the one place SemiBold is allowed.
            Text("Your\nRecovery")
                .font(Theme.Typography.displayHeadline())
                .foregroundStyle(Theme.Colors.ink)
                .lineSpacing(-2)
            Spacer()
            Button { Haptics.tap(); dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.Colors.ink)
                    .frame(width: 44, height: 44)
                    .background(Theme.Colors.ink.opacity(0.05), in: Circle())
            }
        }
        .padding(.bottom, 6)
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
                        Text("logged")
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
                    Text("Streaks")
                        .font(Theme.Typography.label())
                        .foregroundStyle(Theme.Colors.inkLo)
                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Text("\(streak.streaks.count)")
                            .font(Theme.Typography.unitSuffix(34))
                            .foregroundStyle(Theme.Colors.ink)
                            .monospacedDigit()
                        Text("total")
                            .font(Theme.Typography.caption())
                            .foregroundStyle(Theme.Colors.inkLo)
                    }
                    StatusLabel(color: Theme.Colors.good,
                                text: "best \(max(streak.recordSeconds, streak.elapsed).humanShort())",
                                textColor: Theme.Colors.inkLo)
                        .padding(.top, 12)
                }
            }
        }
    }

    private var checkinsCard: some View {
        ivoryCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Check-ins · last 30 days")
                    .font(Theme.Typography.label())
                    .foregroundStyle(Theme.Colors.inkLo)
                MorseStrip(marks: checkinMarks,
                           color: Theme.Colors.ink.opacity(0.7), fade: false)
                Text("goal progress: \(streak.progressPercentText) · average streak: \(averageStreak.humanShort())")
                    .font(Theme.Typography.caption())
                    .foregroundStyle(Theme.Colors.ink.opacity(0.45))
            }
        }
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

/// Streak detail (reached from a Progress streak row). Void scene, glass cards.
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
