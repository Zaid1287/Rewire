import SwiftUI

/// Home top bar: shield-% (green, with warning), flame streak minutes,
/// and the earned level name.
struct HomeStatHeader: View {
    let shieldPercent: Int
    let streakText: String
    let levelName: String
    /// Warning mark next to the shield % — shown while the goal isn't reached.
    var showsWarning: Bool = true

    var body: some View {
        HStack(spacing: 0) {
            // Shield %
            HStack(spacing: 4) {
                Image(systemName: "shield.lefthalf.filled")
                    .foregroundStyle(Theme.Colors.good)
                Text("\(shieldPercent)%")
                    .foregroundStyle(Theme.Colors.good)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                if showsWarning { Text("❗️").font(.system(size: 13)) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Flame streak
            HStack(spacing: 4) {
                Image(systemName: "flame.fill").foregroundStyle(Theme.Colors.butter)
                Text(streakText)
                    .foregroundStyle(Theme.Colors.butter)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity)

            // Level
            HStack(spacing: 4) {
                Image(systemName: "trophy.fill").foregroundStyle(Theme.Colors.textLo)
                Text(levelName)
                    .foregroundStyle(Theme.Colors.textLo)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
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
    HomeStatHeader(shieldPercent: 5, streakText: "1m", levelName: "Newcomer")
        .background { SceneBackground(kind: .void) }
}
