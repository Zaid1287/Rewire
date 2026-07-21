import SwiftUI

/// 21-day Personal Plan (Quit Porn → "21-day Personal Plan"): a day-by-day
/// checklist for quitting porn. No dedicated screenshot, so this follows the
/// WeeklyChallengeView push idiom — header, progress bar, then tappable rows.
/// Days can be completed in any order; completing awards 10 gems (once, not
/// on uncomplete).
struct PersonalPlanView: View {
    @Environment(StreakStore.self) private var streak
    @Environment(GemStore.self) private var gems
    @Environment(\.dismiss) private var dismiss

    private let days = SampleData.personalPlan

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(title: "Day \(max(streak.completedPlanDays.count, 1)) of \(days.count)",
                      showsBack: true, onBack: { dismiss() })

            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    ProgressBarView(value: Double(streak.completedPlanDays.count) / Double(days.count))
                        .padding(.top, Theme.Spacing.sm)

                    VStack(spacing: Theme.Spacing.md) {
                        ForEach(days) { day in
                            planRow(day)
                        }
                    }
                }
                .screenPadding()
                .padding(.top, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.tabBarClearance)
            }
        }
        .background { SceneBackground(kind: .void) }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
    }

    private func planRow(_ day: PlanDay) -> some View {
        let isDone = streak.completedPlanDays.contains(day.day)
        return HStack(spacing: Theme.Spacing.md) {
            IconCircle(symbol: isDone ? "checkmark" : "\(day.day).circle",
                       tint: isDone ? .white : Theme.Colors.textPrimary,
                       background: isDone ? Theme.Colors.good : Theme.Colors.surface2,
                       size: 40,
                       stroke: isDone ? nil : Theme.Colors.textTertiary)
            VStack(alignment: .leading, spacing: 2) {
                Text(day.title)
                    .font(Theme.Typography.headline())
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text(day.detail)
                    .font(Theme.Typography.body())
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
        .contentShape(Rectangle())
        .onTapGesture {
            let wasIncomplete = !isDone
            Haptics.success()
            streak.togglePlanDay(day.day)
            if wasIncomplete { gems.award(10) }
        }
    }
}

#Preview {
    PersonalPlanView().environment(StreakStore()).environment(GemStore())
}
