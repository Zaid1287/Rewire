import SwiftUI

/// "How have others changed their lives?" (IMG_5436): scrolling quote cards with
/// a floating Continue CTA.
struct MoreTestimonialsView: View {
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(title: "How have others changed their lives?")

            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: Theme.Spacing.md) {
                        ForEach(SampleData.quoteTestimonials) { t in
                            TestimonialQuoteCard(item: t)
                        }
                    }
                    .screenPadding()
                    .padding(.top, Theme.Spacing.md)
                    .padding(.bottom, 140)
                }

                BottomFadeScrim()
                    .ignoresSafeArea(edges: .bottom)

                PrimaryButton(title: "Continue", action: onContinue)
                    .screenPadding()
                    .padding(.bottom, Theme.Spacing.md)
            }
        }
        .background(Theme.Colors.background)
    }
}

#Preview { MoreTestimonialsView(onContinue: {}) }
