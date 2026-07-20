import SwiftUI

/// 180° ticked fan gauge with needle dot and a soft glow wedge at the current
/// value — the RonLab score instrument (replaces bars/rings). Draw size should
/// be roughly 2:1.2 (w:h); the arc pivots on the bottom-center.
struct FanGauge: View {
    /// 0…1
    var value: Double
    var tickCount = 33
    var ink: Color = Theme.Colors.ink
    var faint: Color = Theme.Colors.ink.opacity(0.18)
    var glow: Color = Theme.Colors.butter

    var body: some View {
        Canvas { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height - 4)
            let outer = min(size.width / 2, size.height - 8)
            let inner = outer * 0.72
            let needleAngle = Double.pi * (1 + value.clamped01)

            // Glow wedge behind the needle
            var wedge = Path()
            wedge.move(to: c)
            wedge.addArc(center: c, radius: outer + 6,
                         startAngle: .radians(needleAngle - 0.32),
                         endAngle: .radians(needleAngle + 0.32), clockwise: false)
            wedge.closeSubpath()
            ctx.fill(wedge, with: .radialGradient(
                Gradient(colors: [glow.opacity(0.5), glow.opacity(0)]),
                center: c, startRadius: 0, endRadius: outer + 6))

            // Ticks
            for i in 0...tickCount {
                let f = Double(i) / Double(tickCount)
                let a = Double.pi * (1 + f)
                let on = f <= value.clamped01
                var tick = Path()
                tick.move(to: CGPoint(x: c.x + cos(a) * inner, y: c.y + sin(a) * inner))
                tick.addLine(to: CGPoint(x: c.x + cos(a) * outer, y: c.y + sin(a) * outer))
                ctx.stroke(tick, with: .color(on ? ink : faint),
                           style: StrokeStyle(lineWidth: on ? 1.8 : 1.3, lineCap: .round))
            }

            // Needle dot
            let nr = inner - 10
            let p = CGPoint(x: c.x + cos(needleAngle) * nr, y: c.y + sin(needleAngle) * nr)
            ctx.fill(Path(ellipseIn: CGRect(x: p.x - 4.5, y: p.y - 4.5, width: 9, height: 9)),
                     with: .color(ink))
        }
    }
}

private extension Double {
    var clamped01: Double { Swift.min(Swift.max(self, 0), 1) }
}
