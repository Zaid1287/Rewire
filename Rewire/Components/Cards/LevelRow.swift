import SwiftUI

/// A level row: trophy + "N. Name", trailing either the gem cost or the
/// "You are here" current-level marker.
struct LevelRow: View {
    let level: Level

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Text("🏆").font(.system(size: 30))

            Text("\(level.rank). \(level.name)")
                .font(Theme.Typography.cardTitle())
                .foregroundStyle(Theme.Colors.textPrimary)

            Spacer(minLength: Theme.Spacing.xs)

            if level.isCurrent {
                HStack(spacing: Theme.Spacing.xs) {
                    Circle()
                        .fill(Theme.Colors.blue)
                        .frame(width: 20, height: 20)
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                    Text("You are here")
                        .font(Theme.Typography.body())
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
            } else if let cost = level.gemCost {
                HStack(spacing: Theme.Spacing.xs) {
                    GemIcon(size: 20)
                    Text("\(cost)")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.Colors.blueLight)
                }
            }
        }
        .padding(.vertical, Theme.Spacing.md)
    }
}
