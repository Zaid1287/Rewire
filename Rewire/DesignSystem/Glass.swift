import SwiftUI

/// RonLab glass recipes. Smoked = dark-scene frosted card; milk = light-scene.
/// State tint (ember/butter flush) comes from a glow BEHIND the card, never a
/// tinted fill — put the glow in the scene, not here.
struct GlassModifier: ViewModifier {
    var radius: CGFloat = 32
    var milk = false

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        content
            .background {
                shape.fill(.ultraThinMaterial)
                    .environment(\.colorScheme, milk ? .light : .dark)
                    .overlay(shape.fill(milk ? Color(hex: 0xEDF1F4).opacity(0.5)
                                             : Color.white.opacity(0.06)))
                    .overlay(
                        shape.strokeBorder(
                            LinearGradient(
                                colors: milk
                                    ? [.white.opacity(0.5), .white.opacity(0.1)]
                                    : [.white.opacity(0.22), .white.opacity(0.03)],
                                startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1))
                    .shadow(color: .black.opacity(milk ? 0.16 : 0.35),
                            radius: milk ? 50 : 40, y: milk ? 24 : 20)
            }
    }
}

/// Static instances so previews/call sites can pick one dynamically.
enum AnyGlass {
    static let smoked = GlassModifier(milk: false)
    static let milk = GlassModifier(milk: true)
}

extension View {
    func smokedGlass(radius: CGFloat = 32) -> some View {
        modifier(GlassModifier(radius: radius, milk: false))
    }
    func milkGlass(radius: CGFloat = 32) -> some View {
        modifier(GlassModifier(radius: radius, milk: true))
    }

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
