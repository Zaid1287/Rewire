import SwiftUI

/// Levels (IMG_5465): a ranked ladder earned purely from real clean time —
/// no gems, no purchase. The current level is derived from the user's best
/// clean run; every tier above it shows the day count still needed.
struct LevelsView: View {
    @Environment(StreakStore.self) private var streak
    @Environment(\.dismiss) private var dismiss

    private var currentLevel: Level { SampleData.level(forDays: streak.bestRunDays) }
    private var nextLevel: Level? { SampleData.nextLevel(forDays: streak.bestRunDays) }

    private var progressHint: String? {
        guard let next = nextLevel else { return nil }
        let remaining = max(0, next.dayThreshold - streak.bestRunDays)
        return "\(remaining) day\(remaining == 1 ? "" : "s") to \(next.name)"
    }

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(title: "Levels", showsBack: true, onBack: { dismiss() })
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    SectionHeader("Levels")
                    if let progressHint {
                        Text(progressHint)
                            .font(Theme.Typography.body())
                            .foregroundStyle(Theme.Colors.textLo)
                            .padding(.horizontal, 4)
                    }
                    VStack(spacing: 0) {
                        ForEach(Array(SampleData.levels.enumerated()), id: \.element.id) { idx, level in
                            LevelRow(level: level, currentRank: currentLevel.rank)
                                .padding(.horizontal, Theme.Spacing.md)
                            if idx < SampleData.levels.count - 1 { RowDivider(inset: 64) }
                        }
                    }
                    .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
                }
                .screenPadding()
                .padding(.top, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.tabBarClearance)
            }
        }
        .background { SceneBackground(kind: .void) }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview { NavigationStack { LevelsView() }.environment(StreakStore()) }
