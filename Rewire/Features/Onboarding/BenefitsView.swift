import SwiftUI

/// "Benefits that you will get" (IMG_5435): a scrolling list of benefit rows
/// with a floating indigo CTA that reads as a question.
struct BenefitsView: View {
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(title: "Benefits that you will get")

            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: Theme.Spacing.sm) {
                        ForEach(SampleData.benefits) { benefit in
                            Card {
                                BenefitRow(benefit: benefit)
                            }
                        }
                    }
                    .screenPadding()
                    .padding(.top, Theme.Spacing.md)
                    .padding(.bottom, 140)
                }

                BottomFadeScrim()
                    .ignoresSafeArea(edges: .bottom)

                // Commit moment + privacy beat (Phase 5, plan §7): QUITTR's
                // data-leak scandal made on-device privacy the free
                // differentiator — say it where the user commits.
                VStack(spacing: Theme.Spacing.sm) {
                    PrimaryButton(title: "I'm ready to quit my addiction",
                                  action: onContinue)
                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 11))
                        Text("Everything stays on your phone. No account, no server, no leak.")
                    }
                    .font(Theme.Typography.caption())
                    .foregroundStyle(Theme.Colors.textSecondary)
                }
                .screenPadding()
                .padding(.bottom, Theme.Spacing.md)
            }
        }
        .background { SceneBackground(kind: .void) }
    }
}

#Preview { BenefitsView(onContinue: {}) }
