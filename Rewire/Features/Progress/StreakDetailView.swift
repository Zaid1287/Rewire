import SwiftUI

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
