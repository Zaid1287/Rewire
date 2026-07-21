import SwiftUI

/// Onboarding social proof (IMG_5427): chat testimonials, a 5-star "100k+ happy
/// users" centerpiece flanked by laurels, and a "Start my test" CTA.
struct SocialProofView: View {
    var onStart: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    HStack(spacing: Theme.Spacing.sm) {
                        Circle().fill(Theme.Colors.red).frame(width: 22, height: 22)
                        Text("Everyone has started joining July challenge.")
                            .font(Theme.Typography.cardTitle())
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, Theme.Spacing.xxl)

                    TestimonialBubble(item: SampleData.chatTestimonials[0])
                    TestimonialBubble(item: SampleData.chatTestimonials[1])

                    // Centerpiece
                    HStack(spacing: Theme.Spacing.md) {
                        LaurelBranch(mirrored: false)
                        VStack(spacing: Theme.Spacing.xs) {
                            HStack(spacing: 4) {
                                ForEach(0..<5, id: \.self) { _ in
                                    Image(systemName: "star.fill").foregroundStyle(Theme.Colors.star)
                                }
                            }
                            Text("100k+ porn free\nhappy users")
                                .font(Theme.Typography.title())
                                .foregroundStyle(Theme.Colors.textPrimary)
                                .multilineTextAlignment(.center)
                        }
                        LaurelBranch(mirrored: true)
                    }
                    .padding(.vertical, Theme.Spacing.md)

                    TestimonialBubble(item: SampleData.chatTestimonials[2])
                    TestimonialBubble(item: SampleData.chatTestimonials[3])
                }
                .screenPadding()
                .padding(.bottom, Theme.Spacing.xl)
            }

            VStack(spacing: Theme.Spacing.md) {
                PrimaryButton(title: "Start my test", action: onStart)
                HStack(spacing: 6) {
                    Image(systemName: "checkmark").foregroundStyle(Theme.Colors.textSecondary)
                    Text("Don't worry, it takes less than 30 seconds.")
                        .font(Theme.Typography.subtitle())
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .screenPadding()
            .padding(.bottom, Theme.Spacing.md)
        }
        .background { SceneBackground(kind: .void) }
    }
}

/// Green laurel branch flanking the rating centerpiece.
struct LaurelBranch: View {
    var mirrored: Bool
    var body: some View {
        Image(systemName: "laurel.leading")
            .font(.system(size: 60))
            .foregroundStyle(Theme.Colors.butter)
            .scaleEffect(x: mirrored ? -1 : 1)
    }
}

#Preview { SocialProofView(onStart: {}) }
