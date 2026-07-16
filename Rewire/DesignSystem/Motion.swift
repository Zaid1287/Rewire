import SwiftUI

extension Theme {
    /// Standard animation curves — use these, not ad-hoc durations.
    enum Motion {
        /// On-screen morphs (progress fills, layout shifts) — ease-in-out is right here.
        static let standard = Animation.easeInOut(duration: 0.3)
        /// Entering/exiting content (step swaps, overlays) — ease-out so movement starts instantly.
        static let enter = Animation.easeOut(duration: 0.25)
        /// Momentum gestures only (scrub, celebrations) — visible overshoot.
        static let emphasized = Animation.spring(response: 0.4, dampingFraction: 0.7)
        /// Non-momentum taps that still deserve a spring (tab selection) — no overshoot.
        static let snappy = Animation.spring(response: 0.3, dampingFraction: 1.0)
        static let quick = Animation.easeOut(duration: 0.15)
    }
}

extension AnyTransition {
    /// Directional push for step-based flows: forward slides in from trailing
    /// (back from leading), giving the funnel a spatial direction a plain
    /// crossfade lacks. Pair with Theme.Motion.enter on the step value.
    static func push(forward: Bool) -> AnyTransition {
        .asymmetric(
            insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: forward ? .leading : .trailing).combined(with: .opacity)
        )
    }
}
