import SwiftUI

/// Set Goal (IMG_5442): an info banner and a long grouped list of goal options
/// with the current goal check-marked.
struct SetGoalView: View {
    @Environment(StreakStore.self) private var streak
    @Environment(GemStore.self) private var gems
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(title: "Set Goal", showsBack: true, onBack: { dismiss() })

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    HStack(alignment: .top, spacing: Theme.Spacing.md) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 22))
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Text("It is strongly recommended that you proceed step by step.")
                            .font(Theme.Typography.cardTitle())
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, Theme.Spacing.md)

                    SectionHeader("Goals")

                    VStack(spacing: 0) {
                        ForEach(Array(SampleData.goals.enumerated()), id: \.element.id) { idx, goal in
                            goalRow(goal)
                            if idx < SampleData.goals.count - 1 { RowDivider() }
                        }
                    }
                    .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
                }
                .screenPadding()
                .padding(.bottom, Theme.Spacing.tabBarClearance)
            }
        }
        .background(Theme.Colors.background)
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
    }

    private func goalRow(_ goal: Goal) -> some View {
        let selected = goal.id == streak.goal.id
        return Button {
            Haptics.select()
            streak.setGoal(goal)
            gems.recordAchievement("setGoal")
        } label: {
            HStack {
                Text(goal.label)
                    .font(selected ? Theme.Typography.headline() : Theme.Typography.cardTitle())
                    .fontWeight(selected ? .bold : .regular)
                    .foregroundStyle(Theme.Colors.textPrimary)
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white, Theme.Colors.green)
                        .font(.system(size: 24))
                } else {
                    Circle().stroke(Theme.Colors.textTertiary, lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(Theme.Spacing.md)
        }
        .buttonStyle(.plain)
    }
}
