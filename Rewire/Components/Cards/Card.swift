import SwiftUI

/// Base elevated surface used by most grouped content.
struct Card<Content: View>: View {
    var padding: CGFloat = Theme.Spacing.md
    var fill: Color = Theme.Colors.surface
    var cornerRadius: CGFloat = Theme.Radius.lg
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fill, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

/// Hairline divider matching grouped-list separators.
struct RowDivider: View {
    var inset: CGFloat = 0
    var body: some View {
        Rectangle()
            .fill(Theme.Colors.divider)
            .frame(height: 1)
            .padding(.leading, inset)
    }
}
