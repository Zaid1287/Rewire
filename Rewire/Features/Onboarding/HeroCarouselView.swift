import SwiftUI

/// Onboarding hero — RonLab Void scene with the broken-loop instrument: a tick
/// ring with a gap in it and one dot escaping through the break. Four rotating
/// value-prop lines share the same instrument, so the dots change words, not
/// stock imagery. No paywall lives anywhere in this funnel.
struct HeroCarouselView: View {
    var onContinue: () -> Void
    @State private var page = 0
    @State private var escape: CGFloat = 0
    private let autoAdvance = Timer.publish(every: 3.4, on: .main, in: .common).autoconnect()

    /// Each page: eyebrow, headline lead, butter emphasis, support line.
    private let pages: [(lead: String, accent: String, support: String)] = [
        ("Break the loop.", "Rewire the reward.",
         "A calm, private way back to control — your streak, your urges, your recovery, one honest screen at a time."),
        ("Urges peak,", "then they pass.",
         "One tap opens a breathing tool built for the worst four minutes. Free, forever, no upsell mid-crisis."),
        ("A slip is data,", "not a verdict.",
         "Log the pattern, keep the days you earned. Your record only ever grows."),
        ("Everything stays", "on this phone.",
         "No account, no cloud, no name attached. Private by construction.")
    ]

    private var totalPages: Int { pages.count }

    var body: some View {
        ZStack {
            SceneBackground(kind: .void)

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                loopInstrument
                Spacer(minLength: 0)
                copyBlock
            }
        }
        .onReceive(autoAdvance) { _ in
            withAnimation(Theme.Motion.enter) { page = (page + 1) % totalPages }
        }
        .onAppear {
            // The escaping dot drifts out through the gap, forever.
            withAnimation(.easeInOut(duration: 3.6).repeatForever(autoreverses: false)) {
                escape = 1
            }
        }
    }

    // MARK: The instrument

    private var loopInstrument: some View {
        ZStack {
            // Broken loop: ticks with a gap, butter edges marking the break.
            TickRing(count: 72, gap: 7..<14,
                     inactiveColor: .white.opacity(0.30),
                     edgeColor: Theme.Colors.butter)
                .frame(width: 300, height: 300)

            // Escaping dot + fading trail through the gap.
            GeometryReader { geo in
                let c = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                let angle = (10.0 / 72.0) * 2 * .pi - .pi / 2
                ForEach(0..<4, id: \.self) { k in
                    let r = 128 + CGFloat(k) * 18 + escape * 26
                    Circle()
                        .fill(Theme.Colors.butter.opacity(Double(1 - Double(k) * 0.26) * (1 - escape * 0.55)))
                        .frame(width: 9 - CGFloat(k) * 1.8, height: 9 - CGFloat(k) * 1.8)
                        .position(x: c.x + cos(angle) * r, y: c.y + sin(angle) * r)
                }
            }
            .frame(width: 300, height: 300)
            .allowsHitTesting(false)

            // Inner well + brand mark.
            Circle()
                .fill(Color.white.opacity(0.035))
                .overlay(Circle().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
                .frame(width: 196, height: 196)
            BrandDots(size: 34, color: Theme.Colors.textHi)
        }
        .frame(height: 320)
    }

    // MARK: Copy + CTA

    private var copyBlock: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Rewire".uppercased())
                .font(Theme.Typography.caption())
                .tracking(1.6)
                .foregroundStyle(Theme.Colors.textXlo)

            (Text(pages[page].lead + "\n").foregroundStyle(Theme.Colors.textHi)
             + Text(pages[page].accent).foregroundStyle(Theme.Colors.butter))
                .font(Theme.Typography.hero())
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, alignment: .leading)
                .id(page)
                .transition(.opacity)

            Text(pages[page].support)
                .font(Theme.Typography.subtitle())
                .foregroundStyle(Theme.Colors.textLo)
                .fixedSize(horizontal: false, vertical: true)
                .frame(height: 66, alignment: .top)
                .id(page)
                .transition(.opacity)

            // Page dots — plain, left-aligned; the ring is the hero, not these.
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { i in
                    Circle()
                        .fill(i == page ? Color.white : Color.white.opacity(0.25))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.top, 4)

            PrimaryButton(title: "Begin", action: onContinue)
                .padding(.top, 6)

            // Agreement-on-entry: shown where the user first taps into the
            // app, so no blocking ToS popup is needed.
            Text("By continuing you agree to our [Terms](\(Legal.termsURL.absoluteString)) & [Privacy Policy](\(Legal.privacyURL.absoluteString)). No account needed.")
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Colors.textXlo)
                .tint(Theme.Colors.textLo)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 30)
        .padding(.bottom, Theme.Spacing.xl)
    }
}

#Preview {
    HeroCarouselView(onContinue: {})
}
