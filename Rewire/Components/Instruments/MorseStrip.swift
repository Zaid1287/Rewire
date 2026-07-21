import SwiftUI

/// History as rhythm: rounded dashes/dots of varying length, relapses as red dots.
/// Replaces sparklines and calendars anywhere a "how it's been going" glance is
/// needed. Reads left (oldest, faded) → right (newest).
///
/// Drawn in a Canvas that scales the run to the width it's given — a long
/// history must never widen its container (an over-wide HStack silently
/// stretches the whole screen).
enum MorseMark: Hashable {
    case dash(CGFloat)   // run length in points (8–30 reads well)
    case dot             // single quiet day
    case relapse         // red event dot

    var intrinsicWidth: CGFloat {
        switch self {
        case .dash(let w): w
        case .dot: 3
        case .relapse: 5
        }
    }
}

struct MorseStrip: View {
    var marks: [MorseMark]
    var color: Color = .white
    var relapseColor: Color = Theme.Colors.critical
    /// Fade older marks toward `minOpacity` on the left.
    var fade = true
    var minOpacity: Double = 0.35

    private let spacing: CGFloat = 4
    private let barHeight: CGFloat = 3

    var body: some View {
        Canvas { ctx, size in
            guard !marks.isEmpty else { return }
            let gaps = spacing * CGFloat(marks.count - 1)
            let intrinsic = marks.reduce(0) { $0 + $1.intrinsicWidth } + gaps
            // Squeeze to fit; never stretch beyond the natural rhythm.
            let scale = intrinsic > size.width ? (size.width - gaps) / (intrinsic - gaps) : 1
            let midY = size.height / 2

            var x: CGFloat = 0
            for (i, mark) in marks.enumerated() {
                let t = marks.count <= 1 ? 1 : Double(i) / Double(marks.count - 1)
                let opacity = fade ? minOpacity + (1 - minOpacity) * t : 1

                switch mark {
                case .relapse:
                    // Relapse dots keep their size — they're the signal.
                    let d: CGFloat = 5
                    ctx.fill(Path(ellipseIn: CGRect(x: x, y: midY - d / 2, width: d, height: d)),
                             with: .color(relapseColor))
                    x += d + spacing
                case .dot:
                    let d = max(2, 3 * scale)
                    ctx.fill(Path(ellipseIn: CGRect(x: x, y: midY - d / 2, width: d, height: d)),
                             with: .color(color.opacity(opacity)))
                    x += d + spacing
                case .dash(let w):
                    let dw = max(3, w * scale)
                    ctx.fill(Path(roundedRect: CGRect(x: x, y: midY - barHeight / 2,
                                                      width: dw, height: barHeight),
                                  cornerRadius: barHeight / 2),
                             with: .color(color.opacity(opacity)))
                    x += dw + spacing
                }
            }
        }
        .frame(height: 6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension MorseStrip {
    /// Day history → marks. `true` = clean, `false` = relapse, `nil` = no data
    /// (dot). Consecutive clean days merge into one dash (4pt per day, capped).
    static func marks(fromDays days: [Bool?]) -> [MorseMark] {
        var out: [MorseMark] = []
        var run = 0
        func flushRun() {
            guard run > 0 else { return }
            if run == 1 { out.append(.dot) }
            else { out.append(.dash(min(CGFloat(run) * 4, 30))) }
            run = 0
        }
        for day in days {
            switch day {
            case true?: run += 1
            case false?: flushRun(); out.append(.relapse)
            default: flushRun(); out.append(.dot)
            }
        }
        flushRun()
        return out
    }
}
