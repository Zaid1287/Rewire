import SwiftUI

/// Addiction-score result — RonLab Ember: the score is delivered as an
/// instrument reading (fan gauge + dot-matrix numeral), not a red scare screen
/// with sad faces. Same tiered honesty, none of the theatre.
struct ScoreResultView: View {
    var onReady: () -> Void
    @Environment(AppState.self) private var appState
    @State private var appeared = false

    /// Days to recover, derived from score and rounded to the nearest 10.
    private var recoveryDays: Int {
        let raw = appState.addictionScore * 5 / 2
        return (raw + 5) / 10 * 10
    }

    /// Tier label + copy — a 35% answer set shouldn't read like an 80% one.
    private var tier: (word: String, color: Color, copy: String) {
        switch appState.addictionScore {
        case ..<40:
            ("Mild", Theme.Colors.good,
             "Your dependency reads mild. This is the easiest it will ever be to stop.")
        case ..<70:
            ("Moderate", Theme.Colors.butter,
             "Your dependency reads moderate. Acting now is far easier than acting later.")
        default:
            ("Heavy", Theme.Colors.critical,
             "Your dependency reads heavy. That's not a verdict — it's a starting point with a known path out.")
        }
    }

    var body: some View {
        ZStack {
            SceneBackground(kind: .ember)

            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 40)

                Text("Your result".uppercased())
                    .font(Theme.Typography.caption())
                    .tracking(1.4)
                    .foregroundStyle(Theme.Colors.textXlo)

                // The instrument reading
                HStack(alignment: .center, spacing: 10) {
                    HeroNumeral(value: "\(appState.addictionScore)", unit: "%", size: 92)
                    Spacer(minLength: 0)
                    VStack(alignment: .trailing, spacing: 8) {
                        DotMatrixNumeral(text: String(format: "%02d", appState.addictionScore),
                                         color: Theme.Colors.textHi.opacity(0.75))
                        StatusLabel(color: tier.color, text: tier.word)
                    }
                }
                .padding(.top, 10)

                FanGauge(value: Double(appState.addictionScore) / 100,
                         ink: Theme.Colors.textHi.opacity(0.9),
                         faint: .white.opacity(0.18),
                         glow: tier.color)
                    .frame(height: 130)
                    .padding(.top, 18)

                HStack {
                    Text("mild"); Spacer(); Text("heavy")
                }
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Colors.textXlo)

                Text(tier.copy)
                    .font(Theme.Typography.subtitle())
                    .foregroundStyle(Theme.Colors.textLo)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 24)

                Text("Estimate: about \(recoveryDays) days of clean time before the pull fades.")
                    .font(Theme.Typography.subtitle())
                    .foregroundStyle(Theme.Colors.textHi)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)

                Text("Based on your answers. Not a diagnosis.")
                    .font(Theme.Typography.caption())
                    .foregroundStyle(Theme.Colors.textXlo)
                    .padding(.top, 8)

                Spacer()

                PrimaryButton(title: "I'm ready to start", action: onReady)
                    .padding(.bottom, Theme.Spacing.xl)
            }
            .padding(.horizontal, 30)
        }
    }
}

#Preview { ScoreResultView(onReady: {}).environment(AppState()) }
