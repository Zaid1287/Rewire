import SwiftUI

/// Parametric radial tick instrument — the workhorse of the RonLab language.
/// Covers the onboarding loop ring (gap + edge ticks), the panic breathing dial
/// (full circle, butter progress), and the recovery gauge (270° sweep + position
/// dot). Static Canvas draw; animate by driving `activeFraction`.
struct TickRing: View {
    var count = 64
    /// 0…1 of the sweep lit as "active"; nil = no active portion.
    var activeFraction: Double? = nil
    var startAngle: Angle = .degrees(-90)
    var sweep: Angle = .degrees(360)
    /// Tick indices left out entirely (the "broken loop" gap).
    var gap: Range<Int>? = nil
    var tickLength: CGFloat = 14
    var inactiveColor: Color = .white.opacity(0.25)
    var activeColor: Color = .white.opacity(0.9)
    /// Ticks bordering the gap (drawn heavier, usually butter).
    var edgeColor: Color? = nil
    /// Dot riding just inside the ring at `activeFraction`.
    var positionDot: Color? = nil

    var body: some View {
        Canvas { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let outer = min(size.width, size.height) / 2
            let inner = outer - tickLength
            let fullCircle = abs(sweep.degrees) >= 360
            let denom = Double(fullCircle ? count : count - 1)

            for i in 0..<count {
                if let gap, gap.contains(i) { continue }
                let f = Double(i) / denom
                let a = startAngle.radians + sweep.radians * f
                let isEdge = edgeColor != nil && gap.map {
                    i == $0.lowerBound - 1 || i == $0.upperBound
                } == true
                let isActive = activeFraction.map { f <= $0 } == true

                var path = Path()
                path.move(to: CGPoint(x: c.x + cos(a) * inner, y: c.y + sin(a) * inner))
                path.addLine(to: CGPoint(x: c.x + cos(a) * outer, y: c.y + sin(a) * outer))

                let color = isEdge ? edgeColor! : (isActive ? activeColor : inactiveColor)
                ctx.stroke(path, with: .color(color),
                           style: StrokeStyle(lineWidth: isEdge ? 2.2 : (isActive ? 1.8 : 1.4),
                                              lineCap: .round))
            }

            if let positionDot, let f = activeFraction {
                let a = startAngle.radians + sweep.radians * f
                let r = inner - 10
                let p = CGPoint(x: c.x + cos(a) * r, y: c.y + sin(a) * r)
                ctx.fill(Path(ellipseIn: CGRect(x: p.x - 5, y: p.y - 5, width: 10, height: 10)),
                         with: .color(positionDot))
            }
        }
    }
}

#Preview("TickRing variants") {
    ZStack {
        SceneBackground(kind: .void)
        VStack(spacing: 40) {
            // Broken loop (onboarding)
            TickRing(count: 72, gap: 7..<14,
                     inactiveColor: .white.opacity(0.30),
                     edgeColor: Theme.Colors.butter)
                .frame(width: 220, height: 220)
            // Breathing dial (panic)
            TickRing(count: 64, activeFraction: 0.34,
                     inactiveColor: .white.opacity(0.28),
                     activeColor: Theme.Colors.butter)
                .frame(width: 200, height: 200)
            // Recovery gauge, 270°
            TickRing(count: 66, activeFraction: 0.52,
                     startAngle: .degrees(135), sweep: .degrees(270),
                     tickLength: 16,
                     inactiveColor: .white.opacity(0.22),
                     positionDot: Theme.Colors.butter)
                .frame(width: 220, height: 220)
        }
    }
}
