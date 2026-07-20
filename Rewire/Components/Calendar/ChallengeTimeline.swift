import SwiftUI

/// Horizontal milestone rail on the My Streak sheet: a green start nub, then
/// framed calendar markers at 7 / 14 / 30 days.
struct ChallengeTimeline: View {
    /// Which milestone is the active/next target (highlighted orange).
    var activeMilestone: Int = 7
    private let milestones = [7, 14, 30]

    var body: some View {
        HStack(spacing: 0) {
            // Start nub
            Capsule()
                .fill(Theme.Colors.green)
                .frame(width: 52, height: 18)
            segment
            ForEach(Array(milestones.enumerated()), id: \.offset) { idx, m in
                milestoneMarker(m)
                if idx < milestones.count - 1 { segment }
            }
        }
    }

    private var segment: some View {
        Rectangle()
            .fill(Theme.Colors.surface2)
            .frame(height: 14)
            .frame(maxWidth: .infinity)
    }

    private func milestoneMarker(_ value: Int) -> some View {
        let active = value == activeMilestone
        return Text("\(value)")
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundStyle(active ? .black : Theme.Colors.textSecondary)
            .frame(width: 56, height: 56)
            .background(active ? .white : Theme.Colors.surface3,
                        in: RoundedRectangle(cornerRadius: Theme.Radius.sm))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.sm)
                    .stroke(active ? Theme.Colors.flame : Color.clear, lineWidth: 3)
            )
    }
}
