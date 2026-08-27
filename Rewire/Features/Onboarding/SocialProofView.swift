import SwiftUI

/// Onboarding social proof: an honest, checkable "built from 3,800+ real
/// recovery reviews" centerpiece flanked by laurels, and a "Start my test" CTA.
/// (Fabricated user counts, fake-FOMO copy, and invented testimonials were cut —
/// see §0 of SOP.md; presenting them as real is a dark pattern.)
struct SocialProofView: View {
    var onStart: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    Spacer().frame(height: Theme.Spacing.xxl)

                    // Honest centerpiece: a true, checkable claim about how the
                    // app was built — not an invented user count or fake FOMO.
                    HStack(spacing: Theme.Spacing.md) {
                        LaurelBranch(mirrored: false)
                        VStack(spacing: Theme.Spacing.xs) {
                            HStack(spacing: 4) {
                                ForEach(0..<5, id: \.self) { _ in
                                    Image(systemName: "star.fill").foregroundStyle(Theme.Colors.butter)
                                }
                            }
                            Text("Built from 3,800+\nreal recovery reviews")
                                .font(Theme.Typography.title())
                                .foregroundStyle(Theme.Colors.textPrimary)
                                .multilineTextAlignment(.center)
                        }
                        LaurelBranch(mirrored: true)
                    }
                    .padding(.vertical, Theme.Spacing.md)

                    Text("We read thousands of App Store reviews and recovery threads, then built every screen around what actually helps — and cut what makes people quit.")
                        .font(Theme.Typography.subtitle())
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, Theme.Spacing.sm)
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
