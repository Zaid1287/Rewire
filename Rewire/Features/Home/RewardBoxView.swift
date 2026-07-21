import SwiftUI

/// Reward-box opening interstitial (IMG_5455): a treasure chest with a shimmer,
/// "Your reward box is opening…". Auto-dismisses after the animation.
struct RewardBoxView: View {
    @Environment(GemStore.self) private var gems
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var wiggle = false

    var body: some View {
        VStack(spacing: Theme.Spacing.xxl) {
            Spacer()
            ChestMark(size: 150)
                .rotationEffect(.degrees(wiggle ? -4 : 4))
                .animation(.easeInOut(duration: 0.35).repeatForever(autoreverses: true), value: wiggle)
                .overlay(alignment: .topTrailing) {
                    GemIcon(size: 40).offset(x: -6, y: 6)
                }
            Text("Your reward box is opening...")
                .font(Theme.Typography.title())
                .foregroundStyle(Theme.Colors.textPrimary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { SceneBackground(kind: .void) }
        .onAppear {
            // Repeat-forever rotation is the classic vestibular trigger — the
            // chest just sits still under Reduce Motion, copy carries the beat.
            if !reduceMotion { wiggle = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                gems.award(50)
                dismiss()
            }
        }
    }
}

#Preview { RewardBoxView().environment(GemStore()) }
