import SwiftUI

/// Levels (IMG_5465): a ranked trophy list with gem costs and the current-level
/// marker. Header carries the user's gem balance.
struct LevelsView: View {
    @Environment(GemStore.self) private var gems
    @Environment(\.dismiss) private var dismiss
    @State private var showInsufficientGemsAlert = false

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(title: "Levels", showsBack: true, onBack: { dismiss() })
                .overlay(alignment: .trailing) {
                    GemPill(count: gems.gems).padding(.trailing, Theme.Spacing.screen)
                }
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    SectionHeader("Levels")
                    VStack(spacing: 0) {
                        ForEach(Array(SampleData.levels.enumerated()), id: \.element.id) { idx, level in
                            let row = level.rank == gems.currentLevel
                                ? Level(rank: level.rank, name: level.name, gemCost: nil, isCurrent: true)
                                : Level(rank: level.rank, name: level.name, gemCost: level.gemCost, isCurrent: false)
                            Group {
                                if level.rank == gems.currentLevel + 1 {
                                    Button(action: { attemptAdvance(level) }) {
                                        LevelRow(level: row)
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    LevelRow(level: row)
                                }
                            }
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
        .rewireAlert(isPresented: showInsufficientGemsAlert) {
            RewireAlert(
                title: "Not enough gems",
                message: "Keep earning gems to unlock the next level.",
                confirmTitle: "OK",
                confirmIsDestructive: false,
                onCancel: { showInsufficientGemsAlert = false },
                onConfirm: { showInsufficientGemsAlert = false }
            )
        }
    }

    private func attemptAdvance(_ level: Level) {
        guard let cost = level.gemCost else { return }
        if gems.spend(cost) {
            Haptics.success()
            gems.advanceLevel()
        } else {
            showInsufficientGemsAlert = true
        }
    }
}

#Preview { NavigationStack { LevelsView() }.environment(GemStore()) }
