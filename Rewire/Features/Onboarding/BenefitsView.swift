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
                    .padding(.bottom, 100)
                }

                PrimaryButton(title: "How have others changed their lives?",
                              action: onContinue)
                    .screenPadding()
                    .padding(.bottom, Theme.Spacing.md)
            }
        }
        .background(Theme.Colors.background)
    }
}

#Preview { BenefitsView(onContinue: {}) }
