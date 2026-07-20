import SwiftUI

/// Material-style tap ripple (Reddit/Instagram dock feel): a soft circle
/// expands from the exact touch point and fades. Feedback only — fast, subtle,
/// clipped to the control, and skipped entirely under Reduce Motion.
struct TapRippleModifier: ViewModifier {
    @State private var ripples: [Ripple] = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    struct Ripple: Identifiable {
        let id = UUID()
        let center: CGPoint
    }

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geo in
                    ForEach(ripples) { ripple in
                        RippleCircle(center: ripple.center, size: geo.size) {
                            ripples.removeAll { $0.id == ripple.id }
                        }
                    }
                }
                .clipShape(Capsule())
                .allowsHitTesting(false)
            }
            .simultaneousGesture(
                // minimumDistance 0 → fires on plain taps; the tab bar's scrub
                // gesture needs 12pt of travel, so the two never fight.
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        guard !reduceMotion else { return }
                        ripples.append(Ripple(center: value.startLocation))
                    }
            )
    }
}

/// One expanding ring of the ripple. Self-removes when done.
private struct RippleCircle: View {
    let center: CGPoint
    let size: CGSize
    let onFinished: () -> Void
    @State private var expanded = false

    /// Radius that guarantees coverage from any touch point in the control.
    private var maxRadius: CGFloat { max(44, hypot(size.width, size.height)) }

    var body: some View {
        Circle()
            .fill(.primary.opacity(0.16))
            .frame(width: maxRadius * 2, height: maxRadius * 2)
            .scaleEffect(expanded ? 1 : 0.08)
            .opacity(expanded ? 0 : 1)
            .position(center)
            .onAppear {
                withAnimation(.easeOut(duration: 0.45)) { expanded = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { onFinished() }
            }
    }
}

extension View {
    /// Adds a touch-point ripple to a tappable control. Capsule-clipped.
    func tapRipple() -> some View {
        modifier(TapRippleModifier())
    }
}
