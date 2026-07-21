import SwiftUI

/// Floating orange "SPECIAL OFFER" countdown that clings to the right edge of
/// the Home screen and ticks down min:sec.
struct OfferBanner: View {
    let minutes: Int
    let seconds: Int

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text("SPECIAL OFFER")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
            HStack(spacing: Theme.Spacing.xs) {
                digit(String(format: "%02d", minutes))
                Text(":").font(.system(size: 26, weight: .bold)).foregroundStyle(.white)
                digit(String(format: "%02d", seconds))
            }
            HStack(spacing: Theme.Spacing.xxl) {
                Text("min").font(.system(size: 12)).foregroundStyle(.white.opacity(0.9))
                Text("sec").font(.system(size: 12)).foregroundStyle(.white.opacity(0.9))
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Theme.Colors.butter, in: RoundedRectangle(cornerRadius: Theme.Radius.md))
        .themeShadow(Theme.Shadows.banner)
    }

    private func digit(_ s: String) -> some View {
        Text(s)
            .font(.system(size: 26, weight: .bold, design: .rounded))
            .foregroundStyle(Theme.Colors.butter)
            .frame(width: 52, height: 52)
            .background(.white, in: RoundedRectangle(cornerRadius: Theme.Radius.sm))
    }
}

#Preview {
    ZStack {
        Theme.Colors.background.ignoresSafeArea()
        OfferBanner(minutes: 5, seconds: 56)
    }
}
