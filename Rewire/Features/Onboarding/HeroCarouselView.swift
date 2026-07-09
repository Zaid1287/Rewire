import SwiftUI

/// Onboarding hero (IMG_5426): full-bleed photo, gradient scrim, headline with
/// green emphasis, page dots, and a Continue CTA.
struct HeroCarouselView: View {
    var onContinue: () -> Void
    @State private var page = 0
    private let totalPages = 6
    /// The original app cycles 6 hero photos; only one is recreatable (see
    /// PLACEHOLDERS.md), so the dots auto-advance for carousel feel while
    /// Continue always moves on — no dead taps on identical content.
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
        // Hero image lives in .background so its scaledToFill overflow can't
        // inflate the layout width and push content off-screen.
        // (Real photo not recreatable — see PLACEHOLDERS.md.)
        .background {
            HeroImagePlaceholder()
                .ignoresSafeArea()
        }
        .onReceive(autoAdvance) { _ in
            withAnimation { page = (page + 1) % totalPages }
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
