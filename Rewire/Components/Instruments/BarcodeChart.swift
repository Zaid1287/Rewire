import SwiftUI

/// Dense 2px-bar micro-chart; the last few bars carry the accent. Sits in stat
/// card footers where a sparkline would normally go.
struct BarcodeChart: View {
    /// Bar heights, 0…1 (scaled to the view height).
    var values: [Double]
    var accentCount = 5
    var barColor: Color = .white.opacity(0.35)
    var accent: Color = Theme.Colors.butter

    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(Array(values.enumerated()), id: \.offset) { i, v in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(i >= values.count - accentCount ? accent : barColor)
                        .frame(width: 2, height: max(3, geo.size.height * v))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
    }
}

/// 5×7 LED dot-matrix numerals — secondary readouts (`68`, `33/54`).
struct DotMatrixNumeral: View {
    var text: String
    var dotSize: CGFloat = 2.8
    var spacing: CGFloat = 2.6
    var color: Color = Theme.Colors.ink

    private static let font: [Character: [String]] = [
        "0": ["01110","10001","10011","10101","11001","10001","01110"],
        "1": ["00100","01100","00100","00100","00100","00100","01110"],
        "2": ["01110","10001","00001","00010","00100","01000","11111"],
        "3": ["11111","00010","00100","00010","00001","10001","01110"],
        "4": ["00010","00110","01010","10010","11111","00010","00010"],
        "5": ["11111","10000","11110","00001","00001","10001","01110"],
        "6": ["00110","01000","10000","11110","10001","10001","01110"],
        "7": ["11111","00001","00010","00100","01000","01000","01000"],
        "8": ["01110","10001","10001","01110","10001","10001","01110"],
        "9": ["01110","10001","10001","01111","00001","00010","01100"],
    ]

    var body: some View {
        let pitch = dotSize + spacing
        let glyphs = text.compactMap { Self.font[$0] }
        Canvas { ctx, _ in
            var ox: CGFloat = 0
            for glyph in glyphs {
                for (ry, row) in glyph.enumerated() {
                    for (rx, bit) in row.enumerated() where bit == "1" {
                        let rect = CGRect(x: ox + CGFloat(rx) * pitch,
                                          y: CGFloat(ry) * pitch,
                                          width: dotSize, height: dotSize)
                        ctx.fill(Path(ellipseIn: rect), with: .color(color))
                    }
                }
                ox += 5 * pitch + spacing * 2.5
            }
        }
        .frame(width: CGFloat(glyphs.count) * (5 * pitch + spacing * 2.5) - spacing * 2.5,
               height: 7 * pitch - spacing)
    }
}
