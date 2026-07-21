import SwiftUI

/// Home "This Week" strip: Sun–Sat headers over dashed/filled day circles.
struct WeekStrip: View {
    enum DayState { case none, today, report, relapse }

    /// index 0 = Sun … 6 = Sat.
    var states: [DayState] = Array(repeating: .none, count: 7)
    private let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(days.enumerated()), id: \.offset) { idx, day in
                VStack(spacing: Theme.Spacing.sm) {
                    Text(day)
                        .font(Theme.Typography.body())
                        .foregroundStyle(Theme.Colors.textPrimary)
                    dayMark(for: idx < states.count ? states[idx] : .none)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private func dayMark(for state: DayState) -> some View {
        switch state {
        case .none:
            Circle()
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                .foregroundStyle(Theme.Colors.textTertiary)
                .frame(width: 22, height: 22)
        case .today:
            Circle().fill(Theme.Colors.textLo).frame(width: 22, height: 22)
        case .report:
            ZStack {
                Circle().fill(Theme.Colors.good)
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 22, height: 22)
        case .relapse:
            Circle().fill(Theme.Colors.critical).frame(width: 22, height: 22)
        }
    }
}
