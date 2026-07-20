import SwiftUI

/// Ruler-style progress: baseline + tick marks (taller every 5th) with a short
/// solid segment showing progress. Used for multi-step flows (check-in 1 of 4).
struct TickRuler: View {
    var ticks = 20
    /// 0…1
    var progress: Double
    var tint: Color = Theme.Colors.ink

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GeometryReader { geo in
                let w = geo.size.width
                Canvas { ctx, size in
                    // baseline
                    var base = Path()
                    base.move(to: CGPoint(x: 0, y: size.height - 1))
                    base.addLine(to: CGPoint(x: size.width, y: size.height - 1))
                    ctx.stroke(base, with: .color(tint.opacity(0.25)), lineWidth: 1)
                    // ticks
                    for i in 0..<ticks {
                        let x = size.width * CGFloat(i) / CGFloat(ticks - 1)
                        let h: CGFloat = i.isMultiple(of: 5) ? 12 : 7
                        var t = Path()
                        t.move(to: CGPoint(x: x, y: size.height - 1))
                        t.addLine(to: CGPoint(x: x, y: size.height - 1 - h))
                        ctx.stroke(t, with: .color(tint.opacity(0.3)), lineWidth: 1)
                    }
                }
                // progress segment under the baseline
                Capsule().fill(tint)
                    .frame(width: max(10, w * progress), height: 3)
                    .offset(y: geo.size.height + 3)
            }
            .frame(height: 14)
            Spacer().frame(height: 6)
        }
    }
}

/// Hero numeral + tucked unit suffix: `47 days`, `52 %`.
struct HeroNumeral: View {
    var value: String
    var unit: String? = nil
    var size: CGFloat = 88
    var color: Color = Theme.Colors.textHi

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 8) {
            Text(value)
                .heroNumeralStyle(size: size)
                .foregroundStyle(color)
            if let unit {
                Text(unit)
                    .font(Theme.Typography.unitSuffix(size * 0.26))
                    .foregroundStyle(color.opacity(0.35))
            }
        }
    }
}

/// 8pt status dot + word: `● Critical`, `● Good`.
struct StatusLabel: View {
    var color: Color
    var text: String
    var textColor: Color = Theme.Colors.textLo

    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(text).font(Theme.Typography.label()).foregroundStyle(textColor)
        }
    }
}
