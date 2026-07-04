import SwiftUI

extension View {
    /// Standard horizontal screen inset used by most scrollable content.
    func screenPadding() -> some View {
        padding(.horizontal, Theme.Spacing.screen)
    }

    /// Fills remaining width, left-aligned — common for section rows/headers.
    func fillLeading() -> some View {
        frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Conditionally apply a transform.
    @ViewBuilder
    func `if`<T: View>(_ condition: Bool, transform: (Self) -> T) -> some View {
        if condition { transform(self) } else { self }
    }
}

/// Rounds specific corners (used for bottom sheets: top-only radius).
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
