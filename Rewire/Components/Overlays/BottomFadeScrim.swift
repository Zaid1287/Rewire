import SwiftUI

/// Fade-to-background gradient placed behind floating bottom controls
/// (tab bar, onboarding CTAs) so scrolling content dissolves instead of
/// colliding with them.
struct BottomFadeScrim: View {
    var height: CGFloat = 140

    var body: some View {
        LinearGradient(
            colors: [Theme.Colors.background.opacity(0),
                     Theme.Colors.background.opacity(0.85),
                     Theme.Colors.background],
            startPoint: .top, endPoint: .bottom
        )
        .frame(height: height)
        .allowsHitTesting(false)
    }
}

/// The top-edge counterpart, placed behind the floating glass top bars so
/// content dissolves before it reaches the status bar (Apple's scroll-edge
/// effect) instead of colliding with the clock.
struct TopFadeScrim: View {
    var body: some View {
        LinearGradient(
            colors: [Theme.Colors.background,
                     Theme.Colors.background.opacity(0.85),
                     Theme.Colors.background.opacity(0)],
            startPoint: .top, endPoint: .bottom
        )
        .allowsHitTesting(false)
        .ignoresSafeArea(edges: .top)
    }
}
