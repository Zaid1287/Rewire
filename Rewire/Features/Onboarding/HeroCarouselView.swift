import SwiftUI

/// Onboarding hero (IMG_5426): full-bleed photo, gradient scrim, headline with
/// green emphasis, page dots, and a Continue CTA.
struct HeroCarouselView: View {
    var onContinue: () -> Void
    @State private var page = 0
    private let totalPages = 4
    /// The original app cycles hero photos (not recreatable — see
    /// PLACEHOLDERS.md); we cycle four brand-motif scenes instead, so every
    /// dot corresponds to a real visual. Continue always moves on.
    private let autoAdvance = Timer.publish(every: 2.5, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [.clear, .black.opacity(0.35), Theme.Colors.background],
                startPoint: .center, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                // Announcement chips
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    HStack(spacing: Theme.Spacing.sm) {
                        Circle().fill(Theme.Colors.red).frame(width: 22, height: 22)
                        Text("July challenge is live!")
                            .font(Theme.Typography.headline())
                            .foregroundStyle(.white)
                    }
                    HStack(spacing: Theme.Spacing.sm) {
                        AppLogoSmall()
                        Text("#1 Quit Porn Addiction App")
                            .font(Theme.Typography.headline())
                            .foregroundStyle(.white)
                    }
                }

                // Headline — scale down slightly rather than overflow the
                // screen edge on narrower devices.
                (Text("This will be the best\n")
                    .foregroundStyle(.white)
                 + Text("decision in your life")
                    .foregroundStyle(Theme.Colors.green))
                    .font(Theme.Typography.hero())
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Quit porn addiction. Start to change your life. Boost your success everywhere.")
                    .font(Theme.Typography.body())
                    .foregroundStyle(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)

                // Page dots
                HStack(spacing: Theme.Spacing.xs) {
                    ForEach(0..<totalPages, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? Theme.Colors.green : Theme.Colors.surface3)
                            .frame(width: i == page ? 28 : 22, height: 6)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, Theme.Spacing.md)

                PrimaryButton(title: "Continue", action: onContinue)
            }
            .screenPadding()
            .padding(.bottom, Theme.Spacing.xl)
        }
        // Hero art lives in .background so scaledToFill overflow can't
        // inflate the layout width and push content off-screen.
        // (Real photos not recreatable — see PLACEHOLDERS.md.)
        .background {
            ZStack {
                heroBackdrop
                    .id(page)
                    .transition(.opacity)
            }
            .animation(Theme.Motion.standard, value: page)
            .ignoresSafeArea()
        }
        .onReceive(autoAdvance) { _ in
            withAnimation { page = (page + 1) % totalPages }
        }
    }

    /// One drawn scene per carousel page — page 0 keeps the produced asset,
    /// the rest are motif variations on it (flame streak, level-up, habit
    /// calendar) so the auto-advancing dots show real content.
    @ViewBuilder private var heroBackdrop: some View {
        switch page {
        case 0:  HeroImagePlaceholder()
        case 1:  HeroMotif(symbol: "flame.fill", glow: Theme.Colors.flame,
                           iconColor: Theme.Colors.flame)
        case 2:  HeroMotif(symbol: "trophy.fill", glow: Theme.Colors.gold,
                           iconColor: Theme.Colors.gold)
        default: HeroMotif(symbol: "calendar", glow: Theme.Colors.blue,
                           iconColor: Theme.Colors.blueLight)
        }
    }
}

/// Onboarding hero — produced brand-motif graphic (green rings + shield, dark
/// scrim). Falls back to a gradient if the asset is missing.
struct HeroImagePlaceholder: View {
    var body: some View {
        Image("onboarding_hero")
            .resizable()
            .scaledToFill()
    }
}

/// Drawn hero variant matching the produced asset's language: concentric
/// rings and a soft glow around a single large symbol on near-black.
struct HeroMotif: View {
    let symbol: String
    let glow: Color
    let iconColor: Color

    var body: some View {
        ZStack {
            Theme.Colors.background

            RadialGradient(colors: [glow.opacity(0.30), .clear],
                           center: UnitPoint(x: 0.5, y: 0.32),
                           startRadius: 30, endRadius: 420)

            ZStack {
                ForEach(0..<3, id: \.self) { ring in
                    Circle()
                        .stroke(glow.opacity(0.14 - Double(ring) * 0.04), lineWidth: 1.5)
                        .frame(width: 190 + CGFloat(ring) * 130,
                               height: 190 + CGFloat(ring) * 130)
                }
                Circle()
                    .fill(glow.opacity(0.16))
                    .frame(width: 150, height: 150)
                Image(systemName: symbol)
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 150)
        }
    }
}

/// Small green shield mark used inline in the hero chips.
struct AppLogoSmall: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 7, style: .continuous)
            .fill(Theme.Colors.pastelLime)
            .frame(width: 26, height: 26)
            .overlay(Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.Colors.greenDark))
    }
}

#Preview {
    HeroCarouselView(onContinue: {})
}
