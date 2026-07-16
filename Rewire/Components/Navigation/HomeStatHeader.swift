import SwiftUI

/// Home top bar: shield-% (green, with warning), flame streak minutes,
/// gem count, and a gift icon.
struct HomeStatHeader: View {
    let shieldPercent: Int
    let streakText: String
    let gems: Int
    var gemDelta: String? = nil
    /// Warning mark next to the shield % — shown while the goal isn't reached.
    var showsWarning: Bool = true
    var onGiftTap: () -> Void = {}

    var body: some View {
        HStack(spacing: 0) {
            // Shield %
            HStack(spacing: 4) {
                Image(systemName: "shield.lefthalf.filled")
                    .foregroundStyle(Theme.Colors.green)
                Text("\(shieldPercent)%")
                    .foregroundStyle(Theme.Colors.green)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                if showsWarning { Text("❗️").font(.system(size: 13)) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Flame streak
            HStack(spacing: 4) {
                Image(systemName: "flame.fill").foregroundStyle(Theme.Colors.flame)
                Text(streakText)
                    .foregroundStyle(Theme.Colors.flame)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity)

            // Gems
            HStack(spacing: 4) {
                GemIcon(size: 20)
                Text(gemDelta ?? "\(gems)")
                    .foregroundStyle(gemDelta != nil ? Theme.Colors.green : Theme.Colors.blueLight)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity)

            // Gift
            Button(action: onGiftTap) {
                Text("🎁").font(.system(size: 22))
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        // Floating Liquid Glass capsule — content scrolls underneath it.
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.sm + 2)
        .liquidGlass(in: Capsule())
        .themeShadow(Theme.Shadows.floating)
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.xs)
    }
}

#Preview {
    HomeStatHeader(shieldPercent: 5, streakText: "1m", gems: 250, gemDelta: "+250")
        .background(Theme.Colors.background)
}
