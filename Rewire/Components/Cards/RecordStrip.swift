import SwiftUI

/// The "record" layer of the two-layer streak model (flow-redesign Phase 1):
/// three totals that only ever grow — total clean days, clean-this-month %, and
/// best run — sitting above the resettable current run. Always on screen on Home
/// so a slip subtracts from the run, never from the identity number the user
/// sees. See research/design/flow-redesign-plan.md §2.
struct RecordStrip: View {
    let totalCleanDays: Int
    let cleanThisMonthPercent: Int
    let bestRunDays: Int
    /// Right-side caption — "only ever grows ↑" normally, "survived the slip ✓"
    /// on the morning after a relapse.
    var caption: String = "only ever grows ↑"
    /// Green-outlines the card for the post-slip "what survived" moment.
    var highlighted: Bool = false

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack {
                Text("YOUR RECORD").sectionHeaderStyle()
                Spacer()
                Text(caption)
                    .font(Theme.Typography.caption())
                    .foregroundStyle(Theme.Colors.greenMint)
            }
            HStack(spacing: 0) {
                stat("\(totalCleanDays)", "total clean days")
                divider
                stat("\(cleanThisMonthPercent)%", "clean this month", tint: Theme.Colors.greenMint)
                divider
                stat("\(bestRunDays)d", "best run")
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                .stroke(Theme.Colors.greenMint.opacity(0.35), lineWidth: highlighted ? 1 : 0)
        )
    }

    private func stat(_ value: String, _ key: String, tint: Color = Theme.Colors.textPrimary) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(Theme.Typography.title())
                .foregroundStyle(tint)
                .monospacedDigit()
            Text(key)
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle().fill(Theme.Colors.divider).frame(width: 1, height: 34)
    }
}

#Preview {
    VStack(spacing: 20) {
        RecordStrip(totalCleanDays: 47, cleanThisMonthPercent: 94, bestRunDays: 21)
        RecordStrip(totalCleanDays: 47, cleanThisMonthPercent: 94, bestRunDays: 21,
                    caption: "survived the slip ✓", highlighted: true)
    }
    .padding()
    .background(Theme.Colors.background)
}
