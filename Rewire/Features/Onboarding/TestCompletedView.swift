import SwiftUI

/// Post-quiz interstitial (IMG_5432): sage-green screen, big check, "Test
/// Completed", a faux "Preparing porn blocker…" loader, and a review card.
/// Auto-advances after the loader fills.
struct TestCompletedView: View {
    var onDone: () -> Void
    @State private var progress: CGFloat = 0.15

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 96))
                .foregroundStyle(.white, Theme.Colors.green)

            VStack(spacing: Theme.Spacing.xs) {
                Text("Test Completed")
                    .font(Theme.Typography.title())
                    .foregroundStyle(Theme.Colors.testMintText)
                Text("Thank you for your answers.")
                    .font(Theme.Typography.body())
                    .foregroundStyle(Theme.Colors.testMintText.opacity(0.85))
            }

            Spacer()

            VStack(spacing: Theme.Spacing.md) {
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.4)).frame(height: 12)
                    Capsule().fill(Theme.Colors.testMintText.opacity(0.6))
                        .frame(width: max(30, 260 * progress), height: 12)
                }
                .frame(width: 260)
                Text("Preparing porn blocker...")
                    .font(Theme.Typography.cardTitle())
                    .foregroundStyle(Theme.Colors.testMintText)
            }

            Spacer()

            // Review card
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { _ in
                        Image(systemName: "star.fill").foregroundStyle(Theme.Colors.star).font(.system(size: 16))
                    }
                }
                Text("Thank God I found this app 🙏")
                    .font(Theme.Typography.headline())
                    .foregroundStyle(.black)
                Text("Got rid of the addiction and now live my life happily. Thank you!")
                    .font(Theme.Typography.body())
                    .foregroundStyle(.black.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
            .screenPadding()
            .padding(.bottom, Theme.Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.testMint.ignoresSafeArea())
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2)) { progress = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) { onDone() }
        }
    }
}

#Preview { TestCompletedView(onDone: {}) }
