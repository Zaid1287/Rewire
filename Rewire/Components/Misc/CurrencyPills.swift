import SwiftUI

/// Gem count pill (blue diamond + number) — top-right on quiz & sub-screens.
struct GemPill: View {
    let count: Int
    var animatedDelta: String? = nil   // e.g. "+250" shown in green on Home header

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            GemIcon(size: 22)
            Text(animatedDelta ?? "\(count)")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(animatedDelta != nil ? Theme.Colors.good : Theme.Colors.textPrimary)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.xs)
        .background(Theme.Colors.surface, in: Capsule())
    }
}

/// Coin count pill (gold coin + number) — Settings / My Streak.
struct CoinPill: View {
    let count: Int
    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            CoinIcon(size: 22)
            Text("\(count)")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.Colors.textPrimary)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.xs)
        // Detached floating glass pill, matching the nav chrome.
        .liquidGlass(in: Capsule())
    }
}

/// Blue faceted gem glyph (approximation of the app's diamond asset).
struct GemIcon: View {
    var size: CGFloat = 22
    var body: some View {
        Image(systemName: "diamond.fill")
            .font(.system(size: size))
            .foregroundStyle(
                LinearGradient(colors: [Theme.Colors.textLo, Theme.Colors.textLo],
                               startPoint: .top, endPoint: .bottom)
            )
    }
}

/// Gold coin glyph with a "$".
struct CoinIcon: View {
    var size: CGFloat = 22
    var body: some View {
        ZStack {
            Circle().fill(
                LinearGradient(colors: [Color(hex: 0xFFD34D), Color(hex: 0xE8A317)],
                               startPoint: .top, endPoint: .bottom))
            Text("$").font(.system(size: size * 0.55, weight: .bold)).foregroundStyle(Color(hex: 0x7A4E00))
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    VStack(spacing: 16) {
        GemPill(count: 750)
        GemPill(count: 250, animatedDelta: "+250")
        CoinPill(count: 0)
    }
    .padding()
    .background { SceneBackground(kind: .void) }
}
