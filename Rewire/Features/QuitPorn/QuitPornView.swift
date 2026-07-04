import SwiftUI

/// Quit Porn tab (IMG_5458 / 5459): a hub of feature rows grouped into
/// Recommended / Boost your progress / Willpower / Privacy.
struct QuitPornView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                NavHeader(title: "Quit Porn")
                ScrollView {
                    VStack(spacing: Theme.Spacing.xl) {
                        group("Recommended", SampleData.quitRecommended, iconColor: Theme.Colors.green)
                        group("Boost your progress", SampleData.quitBoost)
                        group("Willpower", SampleData.quitWillpower)
                        group("Privacy", SampleData.quitPrivacy)
                    }
                    .screenPadding()
                    .padding(.top, Theme.Spacing.md)
                    .padding(.bottom, 120)
                }
            }
            .background(Theme.Colors.background)
            .toolbar(.hidden, for: .navigationBar)
        }
        .tint(Theme.Colors.green)
    }

    private func group(_ title: String, _ items: [FeatureItem],
                       iconColor: Color = Theme.Colors.textPrimary) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title)
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                    FeatureRow(item: item, iconColor: item.title.contains("Power up") ? Theme.Colors.green : iconColor)
                        .padding(.horizontal, Theme.Spacing.md)
                    if idx < items.count - 1 { RowDivider(inset: 64) }
                }
            }
            .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
        }
    }
}

#Preview { QuitPornView() }
