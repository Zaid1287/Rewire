import SwiftUI

extension View {
    /// Liquid Glass surface (iOS 26) with a material fallback for older OSes.
    /// Use on floating chrome — top bars, the tab bar, alert cards — so content
    /// visibly scrolls underneath. Pair with `themeShadow(Theme.Shadows.floating)`
    /// for the floating read; glass supplies the material, the shadow the depth.
    @ViewBuilder
    func liquidGlass<S: Shape>(in shape: S) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: shape)
        } else {
            self
                .background(.ultraThinMaterial, in: shape)
                .overlay(shape.stroke(Theme.Colors.divider, lineWidth: 1))
        }
    }
}
