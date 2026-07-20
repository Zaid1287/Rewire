import SwiftUI

/// The RonLab per-screen "scene" — every screen floats on one of these instead of
/// a flat fill. Procedural (no image assets): gradient base, blurred glow blobs,
/// dot-grid texture, film grain.
enum SceneKind {
    case void        // neutral dark home
    case ember       // critical / panic
    case emberDim    // relapse reframe
    case fog         // calm light (check-in)
    case amberFog    // warm (recovery)
    case ivory       // Family B light dashboard
    case slate       // Family B dark (settings)

    /// Foreground world of the scene: true = dark text (light scene).
    var isLight: Bool {
        switch self {
        case .fog, .ivory: return true
        default: return false
        }
    }
}

struct SceneBackground: View {
    let kind: SceneKind

    var body: some View {
        ZStack {
            base
            blobs
            texture
            grain
        }
        .ignoresSafeArea()
    }

    // MARK: layers

    @ViewBuilder private var base: some View {
        switch kind {
        case .void:
            Theme.Colors.background
        case .ember, .emberDim:
            Color(hex: 0x0B0708)
        case .fog:
            LinearGradient(
                colors: [Theme.Colors.fogHi, Color(hex: 0xAFC2CF), Theme.Colors.fogLo],
                startPoint: .top, endPoint: .bottom)
        case .amberFog:
            LinearGradient(
                colors: [Theme.Colors.amberHi, Color(hex: 0x5C4C40), Theme.Colors.amberLo],
                startPoint: .top, endPoint: .bottom)
        case .ivory:
            Theme.Colors.ivory
        case .slate:
            Theme.Colors.slate
        }
    }

    @ViewBuilder private var blobs: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            switch kind {
            case .void:
                glow(Theme.Colors.butter.opacity(0.20), size: w * 0.9)
                    .position(x: w * 0.42, y: h * 0.32)
            case .ember:
                glow(Theme.Colors.emberHi.opacity(0.55), size: w * 1.1)
                    .position(x: w * 1.05, y: h * 0.05)
                glow(Theme.Colors.emberHi.opacity(0.38), size: w * 1.0)
                    .position(x: -w * 0.15, y: h * 0.48)
                glow(Theme.Colors.emberLo.opacity(0.40), size: w * 0.8)
                    .position(x: w * 0.95, y: h * 0.98)
            case .emberDim:
                glow(Theme.Colors.emberHi.opacity(0.16), size: w * 1.1)
                    .position(x: -w * 0.1, y: -h * 0.05)
                glow(Theme.Colors.emberLo.opacity(0.22), size: w * 0.95)
                    .position(x: w * 1.05, y: h * 1.0)
            case .fog:
                glow(Color.white.opacity(0.75), size: w * 0.95)
                    .position(x: w * 0.15, y: h * 0.3)
                glow(Color.white.opacity(0.55), size: w * 0.85)
                    .position(x: w * 0.95, y: h * 0.75)
            case .amberFog:
                glow(Color(hex: 0xD7B99B).opacity(0.50), size: w * 1.0)
                    .position(x: w * 0.15, y: h * 0.2)
                glow(Color(hex: 0xC9A98E).opacity(0.32), size: w * 0.85)
                    .position(x: w * 1.05, y: h * 0.75)
            case .ivory:
                glow(Theme.Colors.butter.opacity(0.28), size: w * 0.9)
                    .position(x: w * 0.5, y: h * 0.34)
            case .slate:
                glow(Theme.Colors.butter.opacity(0.09), size: w * 0.85)
                    .position(x: w * 1.0, y: -h * 0.02)
            }
        }
    }

    private func glow(_ color: Color, size: CGFloat) -> some View {
        RadialGradient(colors: [color, .clear], center: .center,
                       startRadius: 0, endRadius: size / 2)
            .frame(width: size, height: size)
            .blur(radius: 40)
    }

    @ViewBuilder private var texture: some View {
        switch kind {
        case .void, .slate:
            SceneTexture.dotGrid(dark: false).opacity(0.05)
        case .ivory:
            SceneTexture.dotGrid(dark: true).opacity(0.07)
        default:
            EmptyView()
        }
    }

    private var grain: some View {
        SceneTexture.noise
            .opacity(kind == .ember ? 0.05 : kind.isLight ? 0.025 : 0.035)
            .blendMode(.overlay)
            .allowsHitTesting(false)
    }
}

/// One-time generated tiles (no per-frame drawing, no bundled assets).
enum SceneTexture {
    static let noise: Image = {
        let side = 128
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side))
        let img = renderer.image { ctx in
            var rng = SystemRandomNumberGenerator()
            for x in 0..<side {
                for y in 0..<side where Bool.random(using: &rng) {
                    let v = CGFloat.random(in: 0...1, using: &rng)
                    ctx.cgContext.setFillColor(UIColor(white: v, alpha: 1).cgColor)
                    ctx.cgContext.fill(CGRect(x: x, y: y, width: 1, height: 1))
                }
            }
        }
        return Image(uiImage: img.resizableImage(withCapInsets: .zero, resizingMode: .tile))
            .resizable(resizingMode: .tile)
    }()

    private static func dotTile(white: Bool) -> Image {
        let pitch: CGFloat = 24
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: pitch, height: pitch))
        let img = renderer.image { ctx in
            ctx.cgContext.setFillColor((white ? UIColor.white : UIColor.black).cgColor)
            ctx.cgContext.fillEllipse(in: CGRect(x: pitch / 2, y: pitch / 2, width: 1.4, height: 1.4))
        }
        return Image(uiImage: img).resizable(resizingMode: .tile)
    }

    private static let whiteDots = dotTile(white: true)
    private static let blackDots = dotTile(white: false)

    static func dotGrid(dark: Bool) -> Image { dark ? blackDots : whiteDots }
}

#Preview("Scenes") {
    ScrollView(.horizontal) {
        HStack(spacing: 0) {
            ForEach([SceneKind.void, .ember, .emberDim, .fog, .amberFog, .ivory, .slate], id: \.self) { kind in
                ZStack {
                    SceneBackground(kind: kind)
                    VStack(spacing: 16) {
                        Text("47")
                            .heroNumeralStyle(size: 88)
                            .foregroundStyle(kind.isLight ? Theme.Colors.ink : Theme.Colors.textHi)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Card title").font(Theme.Typography.cardTitle())
                            Text("Label: value").font(Theme.Typography.label())
                                .foregroundStyle(.secondary)
                        }
                        .padding(24)
                        .frame(width: 240)
                        .modifier(kind.isLight ? AnyGlass.milk : AnyGlass.smoked)
                        .foregroundStyle(kind.isLight ? Theme.Colors.ink : Theme.Colors.textHi)
                    }
                }
                .frame(width: 300, height: 640)
                .clipped()
            }
        }
    }
    .background(Color.black)
}
