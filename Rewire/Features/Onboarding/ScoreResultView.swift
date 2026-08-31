import SwiftUI

/// Onboarding result — what the quiz can honestly say back.
///
/// **This screen used to invent numbers.** It showed a percentage "dependency"
/// score (floored at 35, so nobody could answer their way to a low one), drew
/// it on a fan gauge, and added *"about N days of clean time before the pull
/// fades"* — the score times 2.5. All of it presented as a reading about the
/// user's brain.
///
/// Made-up numbers are the single harshest signal in the review corpus (1.54★,
/// 85% of them 1–2★), and the same pattern was already cut once, in the
/// "% rewired" gauge. So there is no number here now: the instrument chrome is
/// gone, and what's left is the user's own answers repeated back, the pattern
/// named in words, and a forward line that promises no timeline.
///
/// See `AppState.dependencyReading` for why the old score was not fixable.
struct ScoreResultView: View {
    var onReady: () -> Void
    @Environment(AppState.self) private var appState

    private var reading: AppState.DependencyReading { appState.dependencyReading }

    var body: some View {
        ZStack {
            SceneBackground(kind: .ember)

            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 40)

                Text("What you told us".uppercased())
                    .font(Theme.Typography.caption())
                    .tracking(1.4)
                    .foregroundStyle(Theme.Colors.textXlo)

                Text(reading.band)
                    .font(Theme.Typography.title())
                    .foregroundStyle(Theme.Colors.textHi)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)

                // The evidence for the line above — their answers, not our maths.
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    ForEach(reading.reflections, id: \.self) { line in
                        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                            Circle()
                                .fill(Theme.Colors.butter)
                                .frame(width: 5, height: 5)
                                .padding(.top, 8)
                            Text(line)
                                .font(Theme.Typography.subtitle())
                                .foregroundStyle(Theme.Colors.textLo)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.top, 24)

                Text(reading.outlook)
                    .font(Theme.Typography.subtitle())
                    .foregroundStyle(Theme.Colors.textHi)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 24)

                Text("This is your own answers repeated back — not a diagnosis, and not a prediction.")
                    .font(Theme.Typography.caption())
                    .foregroundStyle(Theme.Colors.textXlo)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)

                Spacer()

                PrimaryButton(title: "I'm ready to start", action: onReady)
                    .padding(.bottom, Theme.Spacing.xl)
            }
            .padding(.horizontal, 30)
        }
    }
}

#Preview { ScoreResultView(onReady: {}).environment(AppState()) }
