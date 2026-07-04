import SwiftUI

/// Home "This Week" strip: Sun–Sat headers over dashed/filled day circles.
struct WeekStrip: View {
    /// index 0 = Sun … 6 = Sat. `filledIndex` marks the current day (blue dot).
    var filledIndex: Int? = nil
    private let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(days.enumerated()), id: \.offset) { idx, day in
                VStack(spacing: Theme.Spacing.sm) {
                    Text(day)
                        .font(Theme.Typography.body())
                        .foregroundStyle(Theme.Colors.textPrimary)
                    if idx == filledIndex {
                        Circle().fill(Color(hex: 0x2C6BE0)).frame(width: 22, height: 22)
                    } else {
                        Circle()
                            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                            .foregroundStyle(Theme.Colors.textTertiary)
                            .frame(width: 22, height: 22)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
