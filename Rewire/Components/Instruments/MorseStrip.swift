import SwiftUI

/// History as rhythm: rounded dashes/dots of varying length, relapses as red dots.
/// Replaces sparklines and calendars anywhere a "how it's been going" glance is
/// needed. Reads left (oldest, faded) → right (newest).
enum MorseMark: Hashable {
    case dash(CGFloat)   // run length in points (8–30 reads well)
    case dot             // single quiet day
    case relapse         // red event dot
}

struct MorseStrip: View {
    var marks: [MorseMark]
    var color: Color = .white
    var relapseColor: Color = Theme.Colors.critical
    /// Fade older marks toward `minOpacity` on the left.
    var fade = true
    var minOpacity: Double = 0.35

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            ForEach(Array(marks.enumerated()), id: \.offset) { i, mark in
                let t = marks.count <= 1 ? 1 : Double(i) / Double(marks.count - 1)
                let opacity = fade ? minOpacity + (1 - minOpacity) * t : 1
                switch mark {
                case .dash(let w):
                    Capsule().fill(color.opacity(opacity))
                        .frame(width: w, height: 3)
                case .dot:
                    Circle().fill(color.opacity(opacity))
                        .frame(width: 3, height: 3)
                case .relapse:
                    Circle().fill(relapseColor)
                        .frame(width: 5, height: 5)
                }
            }
        }
        .frame(height: 5)
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
