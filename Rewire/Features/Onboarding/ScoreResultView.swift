import SwiftUI

/// Addiction-score result (IMG_5433): full red screen, big 80% pill, warning
/// copy, an Average-vs-You bar comparison with mood faces, and the commit CTA.
struct ScoreResultView: View {
    var onReady: () -> Void
    @Environment(AppState.self) private var appState
    @State private var appeared = false

    /// Days to recover, derived from score and rounded to the nearest 10
    /// (default score 80 -> 200, matching the original screenshot copy).
    private var recoveryDays: Int {
        let raw = appState.addictionScore * 5 / 2
        return (raw + 5) / 10 * 10
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: Theme.Spacing.huge)

            Text("\(appState.addictionScore)%")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, Theme.Spacing.xxl)
                .padding(.vertical, Theme.Spacing.sm)
                .background(.white.opacity(0.15), in: Capsule())

            VStack(spacing: Theme.Spacing.xs) {
                Text("Your porn addiction level is serious. Please take action immediately.*")
                    .font(Theme.Typography.cardTitle())
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text("* This is only an estimate.")
                    .font(Theme.Typography.body())
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.top, Theme.Spacing.lg)
            .screenPadding()

            Spacer()

            // Bar comparison
            HStack(alignment: .bottom, spacing: Theme.Spacing.huge) {
                barColumn(title: "Average", height: 60, happy: true)
                barColumn(title: "You", height: 150, happy: false)
            }

            Spacer()

            Text("It may take more than \(recoveryDays) days for you to recover completely.")
                .font(Theme.Typography.cardTitle())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .screenPadding()

            SolidPillButton(title: "I'm ready to quit my addiction", action: onReady)
                .screenPadding()
                .padding(.vertical, Theme.Spacing.md)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.scoreRed.ignoresSafeArea())
    }

    private func barColumn(title: String, height: CGFloat, happy: Bool) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .fill(Theme.Colors.scoreBar)
                .frame(width: 110, height: height)
            Text(title)
                .font(Theme.Typography.cardTitle())
                .foregroundStyle(.white)
            Image(systemName: happy ? "face.smiling" : "face.dashed")
                .font(.system(size: 40))
                .foregroundStyle(.white)
        }
    }
}

#Preview { ScoreResultView(onReady: {}) }
