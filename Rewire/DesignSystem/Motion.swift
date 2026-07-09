import SwiftUI

extension Theme {
    /// Standard animation curves — use these, not ad-hoc durations.
    enum Motion {
        static let standard = Animation.easeInOut(duration: 0.3)
        static let emphasized = Animation.spring(response: 0.4, dampingFraction: 0.7)
        static let quick = Animation.easeOut(duration: 0.15)
    }
}
