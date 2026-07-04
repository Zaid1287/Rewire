import SwiftUI

extension Theme {
    /// Dark UIs lean on surface lightness for elevation; shadows are used
    /// sparingly for genuinely floating elements (tab bar, offer banner, sheets).
    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }

    enum Shadows {
        static let none    = ShadowStyle(color: .clear, radius: 0, x: 0, y: 0)
        static let floating = ShadowStyle(color: .black.opacity(0.35), radius: 16, x: 0, y: 6)
        static let banner   = ShadowStyle(color: .black.opacity(0.30), radius: 12, x: 0, y: 4)
        static let button   = ShadowStyle(color: Theme.Colors.primary.opacity(0.35), radius: 18, x: 0, y: 8)
    }
}

extension View {
    func themeShadow(_ style: Theme.ShadowStyle) -> some View {
        shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}
