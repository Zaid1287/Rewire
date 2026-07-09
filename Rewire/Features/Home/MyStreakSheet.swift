import SwiftUI

/// My Streak (IMG_5448 / 5449): a full-screen sheet with the streak headline,
/// the Rewire challenge milestone rail, a month calendar, and stat cards.
struct MyStreakSheet: View {
    @Environment(StreakStore.self) private var streak
    @Environment(GemStore.self) private var gems
    @Environment(\.dismiss) private var dismiss

    /// Reports with no P/M/O flags at all — a fully clean day.
    private var cleanDaysCount: Int {
        streak.reports.filter { !$0.watchedPorn && !$0.masturbated && !$0.relapsed }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(title: "My Streak") {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .frame(width: 40, height: 40)
                        .overlay(Circle().stroke(Theme.Colors.divider, lineWidth: 1))
                }
            }

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    headline
                    recordNote
                    challengeSection
                    calendarSection
                    bottomStats
                }
                .screenPadding()
                .padding(.top, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.xxl)
            }
        }
        .background(Theme.Colors.background)
    }

    private var headline: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.md) {
            FlameMark(size: 72)
            VStack(alignment: .leading, spacing: 0) {
                Text("\(streak.components.minute)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text("minutes streak")
                    .font(Theme.Typography.cardTitle())
                    .foregroundStyle(Theme.Colors.textPrimary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: Theme.Spacing.xs) {
                HStack(spacing: 4) { GemIcon(size: 20); Text("\(gems.gems)").foregroundStyle(Theme.Colors.blueLight).font(.system(size: 16, weight: .semibold, design: .rounded)) }
                HStack(spacing: 4) { CoinIcon(size: 20); Text("\(gems.coins)").foregroundStyle(Theme.Colors.textPrimary).font(.system(size: 16, weight: .semibold, design: .rounded)) }
            }
        }
    }

    private var recordNote: some View {
        let remaining = streak.recordSeconds - streak.elapsed
        return HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "star.fill").foregroundStyle(Theme.Colors.purple)
            Text(remaining <= 0
                 ? "New record! You've beaten your own streak record."
                 : "\(remaining.humanShort()) left to break your own streak record.")
                .font(Theme.Typography.body())
                .foregroundStyle(Theme.Colors.textPrimary)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.md))
    }

    private var challengeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("Rewire Challenge")
                    .font(Theme.Typography.cardTitle())
                    .foregroundStyle(Theme.Colors.textPrimary)
                Spacer()
                Text("Month 1").font(Theme.Typography.body()).foregroundStyle(Theme.Colors.textSecondary)
            }
            Card(padding: Theme.Spacing.lg) {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    HStack {
                        Text("7 days challenge")
                            .font(Theme.Typography.headline())
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Spacer()
                        Text("Day 1 of 7").font(Theme.Typography.body()).foregroundStyle(Theme.Colors.textSecondary)
                    }
                    ChallengeTimeline(activeMilestone: 7)
                }
            }
        }
    }

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("July 2026")
                    .font(Theme.Typography.cardTitle())
                    .foregroundStyle(Theme.Colors.textPrimary)
                Spacer()
                HStack(spacing: Theme.Spacing.lg) {
                    Label("Prev.", systemImage: "chevron.left")
                        .labelStyle(.titleAndIcon)
                        .font(Theme.Typography.body())
                        .foregroundStyle(Theme.Colors.textSecondary)
                    HStack(spacing: 4) {
                        Text("Next"); Image(systemName: "chevron.right")
                    }
                    .font(Theme.Typography.body())
                    .foregroundStyle(Theme.Colors.textSecondary)
                }
            }

            HStack(spacing: Theme.Spacing.md) {
                LabeledStatCard(symbol: "checkmark", iconBackground: Theme.Colors.green,
                                value: "\(cleanDaysCount)", label: "clean days")
                LabeledStatCard(symbol: "exclamationmark", iconBackground: Theme.Colors.red,
                                value: "\(streak.reports.filter(\.watchedPorn).count)", label: "times watched")
            }

            Card(padding: Theme.Spacing.md) {
                let info = monthCalendarInfo
                MonthCalendar(leadingBlanks: info.leadingBlanks, dayCount: info.dayCount,
                              today: info.today, flaggedDays: info.flaggedDays)
            }
        }
    }

    /// Wet dream / edging come from logged history events (History → Add Event),
    /// which store the option label in `note`.
    private func eventCount(_ label: String) -> Int {
        streak.events.filter { $0.note == label }.count
    }

    /// Current-month geometry for the calendar grid, plus day numbers that
    /// have a saved report (flag marker). MonthCalendar has no relapse-style
    /// marker of its own, so relapse days aren't fed in separately.
    private var monthCalendarInfo: (leadingBlanks: Int, dayCount: Int, today: Int, flaggedDays: Set<Int>) {
        let cal = Calendar.current
        let today = Date()
        let dayCount = cal.range(of: .day, in: .month, for: today)?.count ?? 30
        let firstOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: today)) ?? today
        let leadingBlanks = cal.component(.weekday, from: firstOfMonth) - 1   // Sun-first
        let flaggedDays = Set(streak.reports.compactMap { report -> Int? in
            guard cal.isDate(report.date, equalTo: today, toGranularity: .month) else { return nil }
            return cal.component(.day, from: report.date)
        })
        return (leadingBlanks, dayCount, cal.component(.day, from: today), flaggedDays)
    }

    private var bottomStats: some View {
        HStack(spacing: Theme.Spacing.md) {
            LabeledStatCard(emoji: "💧", iconBackground: Theme.Colors.blue,
                            value: "\(eventCount("Wet dream"))", label: "wet dream")
            LabeledStatCard(emoji: "✋", iconBackground: Color(hex: 0xE8A317),
                            value: "\(eventCount("Edging"))", label: "edging")
        }
    }
}
