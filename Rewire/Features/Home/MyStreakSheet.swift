import SwiftUI

/// My Streak (IMG_5448 / 5449): a full-screen sheet with the streak headline,
/// the No Nut challenge milestone rail, a month calendar, and stat cards.
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
                HStack(spacing: 4) { GemIcon(size: 20); Text("\(gems.gems)").foregroundStyle(Color(hex: 0x6FB2FF)).font(.system(size: 16, weight: .semibold, design: .rounded)) }
                HStack(spacing: 4) { CoinIcon(size: 20); Text("\(gems.coins)").foregroundStyle(Theme.Colors.textPrimary).font(.system(size: 16, weight: .semibold, design: .rounded)) }
            }
        }
    }

    private var recordNote: some View {
        let remaining = streak.recordSeconds - streak.elapsed
        return HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "star.fill").foregroundStyle(Color(hex: 0x8B7BF0))
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
                Text("No Nut Challenge")
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
                                value: "0", label: "times watched")
            }

            Card(padding: Theme.Spacing.md) {
                // July 2026 starts on a Wednesday (leadingBlanks = 3).
                MonthCalendar(leadingBlanks: 3, dayCount: 31, today: 3,
                              flaggedDays: [6, 10, 13, 17, 24])
            }
        }
    }

    private var bottomStats: some View {
        // ponytail: DailyReport has no wet-dream/edging flags, only P/M/O — these
        // stay at 0 until the model grows dedicated fields.
        HStack(spacing: Theme.Spacing.md) {
            LabeledStatCard(emoji: "💧", iconBackground: Color(hex: 0x2C6BE0),
                            value: "0", label: "wet dream")
            LabeledStatCard(emoji: "✋", iconBackground: Color(hex: 0xE8A317),
                            value: "0", label: "edging")
        }
    }
}
