import SwiftUI

/// The one way Premium is ever withheld (PAYWALL-CLUSTER.md §"Consequences" 1).
///
/// **The rules this component exists to keep**, taken from the packaging
/// decision and from what the competitor reviews punish:
///
/// - **Never a hidden dead end.** The row or section stays visible and says
///   plainly what's behind it. A feature that silently disappears reads as a
///   bug; a row that does nothing reads as broken.
/// - **One CTA, no nagging.** A single button. No countdown, no red dot, no
///   second ask, nothing that reappears after it's dismissed.
/// - **Never in the way of a person in crisis.** Nothing gated is reachable
///   from Panic, breathing, the streak or the slip log, so this never renders
///   mid-urge. That is the §0 test the whole packaging decision hangs on.
///
/// Two shapes, same contract: a card for a section that is partly free
/// (history, insights) and a screen for a route that is wholly Premium.

/// Inline card. Sits at the end of a section that free users see a slice of,
/// so the boundary is visible rather than invisible.
struct PremiumGateCard: View {
    let title: String
    let message: String
    var cta: String = "See Premium"

    @Environment(GemStore.self) private var gems
    @Environment(Purchases.self) private var purchases
    @State private var showPaywall = false

    var body: some View {
        // Premium users never see the gate — and neither does anyone else while
        // there is nothing to buy, because a lock with no door is the dead end
        // this component exists to avoid.
        if !gems.isPremium, purchases.canSell {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.Colors.butter)
                    Text(title)
                        .font(Theme.Typography.headline())
                        .foregroundStyle(Theme.Colors.textHi)
                }
                Text(message)
                    .font(Theme.Typography.body())
                    .foregroundStyle(Theme.Colors.textLo)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    Haptics.tap(); showPaywall = true
                } label: {
                    Text(cta)
                        .font(Theme.Typography.bodyMedium())
                        .foregroundStyle(Theme.Colors.butter)
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.Spacing.md)
            .smokedGlass(radius: 24)
            .sheet(isPresented: $showPaywall) {
                PaywallSheet().presentationDetents([.medium, .large])
            }
        }
    }
}

/// Full screen, for a route that is entirely Premium. Keeps the nav bar and
/// the back button, so it is somewhere you arrived rather than a wall you're
/// stuck behind — and it describes the feature honestly instead of teasing it.
struct PremiumGateScreen: View {
    let title: String
    let icon: String
    let pitch: String
    /// Two or three concrete things the feature does. Real capability only —
    /// this screen is read by someone deciding whether to pay.
    let details: [String]

    @Environment(\.dismiss) private var dismiss
    @State private var showPaywall = false

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(title: title, showsBack: true, onBack: { dismiss() })
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    Image(systemName: icon)
                        .font(.system(size: 34))
                        .foregroundStyle(Theme.Colors.butter)
                        .padding(.top, Theme.Spacing.lg)

                    Text(pitch)
                        .font(Theme.Typography.subtitle())
                        .foregroundStyle(Theme.Colors.textHi)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        ForEach(details, id: \.self) { detail in
                            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Theme.Colors.butter)
                                    .padding(.top, 3)
                                Text(detail)
                                    .font(Theme.Typography.body())
                                    .foregroundStyle(Theme.Colors.textLo)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(Theme.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .smokedGlass(radius: 24)

                    PrimaryButton(title: "See Premium") {
                        showPaywall = true
                    }

                    Text("Panic, breathing, the streak, the blocker and daily check-ins stay free — always.")
                        .font(Theme.Typography.caption())
                        .foregroundStyle(Theme.Colors.textXlo)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .screenPadding()
                .padding(.bottom, Theme.Spacing.tabBarClearance)
            }
        }
        .background { SceneBackground(kind: .void) }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showPaywall) {
            PaywallSheet().presentationDetents([.medium, .large])
        }
    }
}
