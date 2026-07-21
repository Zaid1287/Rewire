import SwiftUI

/// Month grid used on the My Streak sheet. Days can carry a flag marker
/// (scheduled), a red "today" highlight, or plain text.
struct MonthCalendar: View {
    /// Leading empty cells before day 1, number of days, today's day number,
    /// and the set of days that show a flag marker.
    let leadingBlanks: Int
    let dayCount: Int
    var today: Int? = nil
    var flaggedDays: Set<Int> = []

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { d in
                    Text(d)
                        .font(Theme.Typography.body())
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: columns, spacing: Theme.Spacing.lg) {
                ForEach(0..<leadingBlanks, id: \.self) { _ in Color.clear.frame(height: 44) }
                ForEach(1...dayCount, id: \.self) { day in
                    dayCell(day)
                }
            }
        }
    }

    @ViewBuilder
    private func dayCell(_ day: Int) -> some View {
        ZStack {
            if day == today {
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .fill(Theme.Colors.critical)
                    .frame(width: 44, height: 44)
            }
            if flaggedDays.contains(day) {
                Image(systemName: "flag.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Color(hex: 0x6B5A3E))
                    .frame(width: 44, height: 44)
            }
            Text("\(day)")
                .font(Theme.Typography.body())
                .foregroundStyle(day == today ? .white
                                 : flaggedDays.contains(day) ? Color(hex: 0xD8B25A)
                                 : Theme.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }
}
