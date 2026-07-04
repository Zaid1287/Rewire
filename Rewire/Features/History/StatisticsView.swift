import SwiftUI

/// Statistics (reached from History → Statistics). No dedicated screenshot, so
/// this is a faithful minimal summary in the app's card/stat idiom.
struct StatisticsView: View {
    @Environment(StreakStore.self) private var streak
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(title: "Statistics", showsBack: true, onBack: { dismiss() })
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    HStack(spacing: Theme.Spacing.md) {
                        LabeledStatCard(symbol: "flame.fill", iconBackground: Theme.Colors.flame,
                                        value: "\(streak.streaks.count)", label: "total streaks")
                        LabeledStatCard(symbol: "checkmark", iconBackground: Theme.Colors.green,
                                        value: "0", label: "clean days")
                    }
                    HStack(spacing: Theme.Spacing.md) {
                        LabeledStatCard(emoji: "📈", iconBackground: Theme.Colors.primary,
                                        value: streak.progressPercentText, label: "goal progress")
                        LabeledStatCard(symbol: "square.and.pencil", iconBackground: Color(hex: 0x8B7BF0),
                                        value: "\(streak.reports.count)", label: "reports")
                    }

                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        SectionHeader("Best streak")
                        Card {
                            HStack {
                                FlameMark(size: 48)
                                Text(streak.recordSeconds.humanShort())
                                    .font(Theme.Typography.title())
                                    .foregroundStyle(Theme.Colors.textPrimary)
                                Spacer()
                            }
                        }
                    }
                }
                .screenPadding()
                .padding(.top, Theme.Spacing.lg)
                .padding(.bottom, 120)
            }
        }
        .background(Theme.Colors.background)
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
    }
}

/// Streak detail (reached from a History streak row). Minimal, style-consistent.
struct StreakDetailView: View {
    let index: Int
    @Environment(StreakStore.self) private var streak
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(title: "Streak #\(index)", showsBack: true, onBack: { dismiss() })
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    Card {
                        HStack(spacing: Theme.Spacing.md) {
                            FlameMark(size: 56)
                            VStack(alignment: .leading) {
                                Text((streak.streaks.first { $0.index == index }?.duration ?? 60).humanShort())
                                    .font(Theme.Typography.title())
                                    .foregroundStyle(Theme.Colors.textPrimary)
                                Text("streak duration")
                                    .font(Theme.Typography.body())
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }
                            Spacer()
                        }
                    }

                    SectionHeader("Daily reports")
                    if streak.reports.isEmpty {
                        Text("No reports saved for this streak yet.")
                            .font(Theme.Typography.body())
                            .foregroundStyle(Theme.Colors.textSecondary)
                    } else {
                        ForEach(streak.reports) { report in
                            Card {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Day \(report.dayNumber)  |  \(RewireDate.full.string(from: report.date))")
                                        .font(Theme.Typography.body())
                                        .foregroundStyle(Theme.Colors.textSecondary)
                                    Text(report.note.isEmpty ? "-" : report.note)
                                        .font(Theme.Typography.body())
                                        .foregroundStyle(Theme.Colors.textPrimary)
                                }
                            }
                        }
                    }
                }
                .screenPadding()
                .padding(.top, Theme.Spacing.lg)
                .padding(.bottom, 120)
            }
        }
        .background(Theme.Colors.background)
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
    }
}
