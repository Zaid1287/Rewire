import SwiftUI

/// "Porn ruins your life" comparison (IMG_5434): two overlapping cards —
/// without Rewire (cons) behind, with Rewire (pros) in front.
struct ComparisonView: View {
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    VStack(spacing: Theme.Spacing.xs) {
                        Text("Porn ruins your life.")
                            .font(Theme.Typography.title())
                            .foregroundStyle(Color(hex: 0xF08A5D))
                        HStack(spacing: Theme.Spacing.xs) {
                            Text("So, you're in the right place")
                                .font(Theme.Typography.title())
                                .foregroundStyle(Theme.Colors.textPrimary)
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.white, Theme.Colors.green)
                                .font(.system(size: 26))
                        }
                    }
                    .multilineTextAlignment(.center)
                    .padding(.top, Theme.Spacing.huge)

                    // Side-by-side cards bleeding off both screen edges, the
                    // "with" card slightly in front and higher (IMG_5434).
                    HStack(alignment: .top, spacing: -36) {
                        ComparisonCard(title: "without Rewire",
                                       titleColor: Theme.Colors.textSecondary,
                                       points: SampleData.withoutPoints, positive: false)
                            .padding(.top, 56)
                        ComparisonCard(title: "with Rewire",
                                       titleColor: Theme.Colors.greenMint,
                                       points: SampleData.withPoints, positive: true)
                            .zIndex(1)
                    }
                    .padding(.horizontal, -(Theme.Spacing.screen + 12))
                }
                .screenPadding()
                .padding(.bottom, Theme.Spacing.xl)
            }

            PrimaryButton(title: "Continue", action: onContinue)
                .screenPadding()
                .padding(.bottom, Theme.Spacing.md)
        }
        .background(Theme.Colors.background)
    }
}

#Preview { ComparisonView(onContinue: {}) }
