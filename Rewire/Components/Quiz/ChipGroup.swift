import SwiftUI

/// A labelled group of single-select pill chips that wrap across lines. Used by
/// the Slip Log's when / trigger / feeling triad (flow-redesign Phase 2).
struct ChipGroup: View {
    let title: String
    let options: [String]
    @Binding var selection: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(title).sectionHeaderStyle()
            FlowLayout(spacing: Theme.Spacing.xs) {
                ForEach(options, id: \.self) { option in
                    Chip(text: option, selected: selection == option) {
                        Haptics.select()
                        selection = (selection == option) ? nil : option
                    }
                }
            }
        }
    }
}

/// One pill chip. Green-filled when selected.
private struct Chip: View {
    let text: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(Theme.Typography.bodyMedium())
                .foregroundStyle(selected ? Theme.Colors.good : Theme.Colors.textSecondary)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, 10)
                .background(selected ? Theme.Colors.good.opacity(0.14) : Theme.Colors.surface,
                            in: Capsule())
                .overlay(Capsule().stroke(selected ? Theme.Colors.good : Theme.Colors.divider,
                                          lineWidth: 1))
        }
        .buttonStyle(PressableButtonStyle())
    }
}

/// Minimal left-to-right wrapping layout (iOS 17 Layout). Rows fill to the
/// proposed width, then wrap; no external dependency.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0; y += rowHeight + spacing; rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX; y += rowHeight + spacing; rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    struct Demo: View {
        @State var sel: String? = "Late night"
        var body: some View {
            ChipGroup(title: "When did it happen?",
                      options: SampleData.slipTimesOfDay, selection: $sel)
                .padding()
                .background { SceneBackground(kind: .void) }
        }
    }
    return Demo()
}
