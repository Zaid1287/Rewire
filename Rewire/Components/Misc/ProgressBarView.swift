import SwiftUI

/// Rounded progress bar (green fill on a dark track). Used for quiz progress,
/// goal progress, and superpower meters.
struct ProgressBarView: View {
    var value: Double            // 0…1
    var height: CGFloat = 10
    var fill: Color = Theme.Colors.greenMint
    var track: Color = Theme.Colors.surface2

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule()
                    .fill(fill)
                    .frame(width: max(height, geo.size.width * min(1, max(0, value))))
            }
        }
        .frame(height: height)
        .animation(Theme.Motion.standard, value: value)
    }
}

#Preview {
    VStack(spacing: 20) {
        ProgressBarView(value: 0.15)
        ProgressBarView(value: 0.6, height: 6)
        ProgressBarView(value: 1.0)
    }
    .padding()
    .background(Theme.Colors.background)
}
