import SwiftUI

/// A level row: trophy + "N. Name", trailing the "You are here" marker for
/// the derived current level, a reached checkmark for tiers already passed,
/// or the day threshold still needed for tiers ahead.
struct LevelRow: View {
    let level: Level
    let currentRank: Int

    private var isCurrent: Bool { level.rank == currentRank }
    private var isReached: Bool { level.rank < currentRank }

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Text("🏆").font(.system(size: 30))

            Text("\(level.rank). \(level.name)")
                .font(Theme.Typography.cardTitle())
                .foregroundStyle(Theme.Colors.textPrimary)

            Spacer(minLength: Theme.Spacing.xs)

            if isCurrent {
                HStack(spacing: Theme.Spacing.xs) {
                    Circle()
                        .fill(Theme.Colors.textLo)
                        .frame(width: 20, height: 20)
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                    Text("You are here")
                        .font(Theme.Typography.body())
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
            } else if isReached {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.Colors.good)
                    Text("Reached")
                        .font(Theme.Typography.body())
                        .foregroundStyle(Theme.Colors.textLo)
                }
            } else {
                Text("Reach day \(level.dayThreshold)")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.Colors.textLo)
            }
        }
        .padding(.vertical, Theme.Spacing.md)
    }
}
