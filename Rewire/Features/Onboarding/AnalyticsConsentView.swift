import SwiftUI

/// The analytics ask, placed inside onboarding.
///
/// **Why this screen exists.** Consent used to live only in Settings, which a
/// user reaches *after* onboarding — and analytics is off by default. So every
/// event emitted during onboarding (`onboarding_step`, `onboarding_completed`,
/// `onboarding_paywall_shown`, `onboarding_paywall_skipped`) was dropped for
/// every user, always. The acquisition funnel was unmeasurable by construction
/// and that code was dead in practice. Asking here is what makes it real.
///
/// **It is a question, not a gate.** Both answers are full-width buttons of the
/// same size. Declining is one tap, costs nothing, and is never asked again —
/// no second prompt later in the funnel, no nag. It sits immediately after the
/// hero's "no account, no cloud" promise on purpose: the honest place to ask is
/// right where we make the claim, and the answer is still no by default.
///
/// Whichever way they answer, the choice routes through
/// `AppState.setAnalyticsOptIn` — the same single setter Settings uses — so
/// there is one consent path in the app, and Settings always reflects and can
/// reverse what was chosen here.
struct AnalyticsConsentView: View {
    /// Called with the user's answer once they've made it.
    var onAnswer: (Bool) -> Void

    var body: some View {
        ZStack {
            SceneBackground(kind: .void)

            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 40)

                Text("Before we start".uppercased())
                    .font(Theme.Typography.caption())
                    .tracking(1.4)
                    .foregroundStyle(Theme.Colors.textXlo)

                Text("Can we count the taps?")
                    .font(Theme.Typography.title())
                    .foregroundStyle(Theme.Colors.textHi)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)

                Text("Knowing which screens people actually use is how this app gets better. It's the only thing we'd ever collect.")
                    .font(Theme.Typography.subtitle())
                    .foregroundStyle(Theme.Colors.textLo)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 16)

                // Spelled out both ways round. The reassurance is the specific
                // list of what can't be sent, not an adjective like "safe".
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    line(icon: "checkmark", tint: Theme.Colors.good,
                         text: "Which screens get opened, and where people give up")
                    line(icon: "xmark", tint: Theme.Colors.critical,
                         text: "Never your slips, your reasons, your notes or your photos")
                    line(icon: "xmark", tint: Theme.Colors.critical,
                         text: "No account, no profile, no name — nothing that points back at you")
                }
                .padding(Theme.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .smokedGlass(radius: 24)
                .padding(.top, 24)

                Spacer()

                PrimaryButton(title: "Share anonymous usage") { onAnswer(true) }

                // Same width, same height, same reachability as the accept
                // button. A decline that reads as an afterthought is a dark
                // pattern wearing a polite face.
                Button { Haptics.tap(); onAnswer(false) } label: {
                    Text("No thanks")
                        .font(Theme.Typography.button())
                        .foregroundStyle(Theme.Colors.textHi)
                        .frame(maxWidth: .infinity)
                        .frame(height: 62)
                        .background(Theme.Colors.surface2, in: Capsule())
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.top, Theme.Spacing.sm)

                Text("You can change this any time in Settings.")
                    .font(Theme.Typography.caption())
                    .foregroundStyle(Theme.Colors.textXlo)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 12)
                    .padding(.bottom, Theme.Spacing.xl)
            }
            .padding(.horizontal, 30)
        }
    }

    private func line(icon: String, tint: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 16)
                .padding(.top, 4)
            Text(text)
                .font(Theme.Typography.body())
                .foregroundStyle(Theme.Colors.textLo)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview { AnalyticsConsentView(onAnswer: { _ in }) }
