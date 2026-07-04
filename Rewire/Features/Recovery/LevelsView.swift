import SwiftUI

/// Levels (IMG_5465): a ranked trophy list with gem costs and the current-level
/// marker. Header carries the user's gem balance.
struct LevelsView: View {
    @Environment(GemStore.self) private var gems
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(title: "Levels", showsBack: true, onBack: { dismiss() })
                .overlay(alignment: .trailing) {
                    GemPill(count: 650).padding(.trailing, Theme.Spacing.screen)
                }
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    SectionHeader("Levels")
                    VStack(spacing: 0) {
                        ForEach(Array(SampleData.levels.enumerated()), id: \.element.id) { idx, level in
                            LevelRow(level: level).padding(.horizontal, Theme.Spacing.md)
                            if idx < SampleData.levels.count - 1 { RowDivider(inset: 64) }
                        }
                    }
                    .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
                }
                .screenPadding()
                .padding(.top, Theme.Spacing.md)
                .padding(.bottom, 120)
            }
        }
        .background(Theme.Colors.background)
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview { NavigationStack { LevelsView() }.environment(GemStore()) }
