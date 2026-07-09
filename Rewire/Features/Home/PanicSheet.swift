import SwiftUI

/// Panic Button sheet. Free users see the premium upsell (IMG_5456): siren,
/// three benefit rows, and an "Unlock Premium Features" CTA. Premium users get
/// the real tool: a guided breathing exercise, an urge timer, and rotating
/// encouragement, ending in an "I'm Safe Now" gem reward.
struct PanicSheet: View {
    @Environment(GemStore.self) private var gems
    @Environment(\.dismiss) private var dismiss
    @State private var showPaywall = false

    private let points: [(String, String)] = [
        ("Saves your streak", "Stay safe with the panic button."),
        ("You will need this", "Your first 30 days won't be easy."),
        ("Reach your goals faster", "This will be a game-changer for you.")
    ]

    var body: some View {
        Group {
            if gems.isPremium {
                PanicModeView()
            } else {
                upsell
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background)
        .onAppear { gems.recordAchievement("panic") }
        .sheet(isPresented: $showPaywall) {
            PaywallSheet().presentationDetents([.medium, .large])
        }
    }

    private var upsell: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Capsule().fill(Theme.Colors.textTertiary).frame(width: 40, height: 5)
                .padding(.top, Theme.Spacing.sm)

            Spacer()

            SirenIcon()

            Text("Panic Button")
                .font(Theme.Typography.title())
                .foregroundStyle(Theme.Colors.textPrimary)

            VStack(spacing: 0) {
                ForEach(Array(points.enumerated()), id: \.offset) { idx, p in
                    HStack(alignment: .top, spacing: Theme.Spacing.md) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.white, Theme.Colors.green)
                            .font(.system(size: 24))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(p.0).font(Theme.Typography.headline())
                                .foregroundStyle(Theme.Colors.textPrimary)
                            Text(p.1).font(Theme.Typography.body())
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, Theme.Spacing.md)
                    if idx < points.count - 1 { RowDivider() }
                }
            }
            .screenPadding()

            PrimaryButton(title: "Unlock Premium Features") { showPaywall = true }
                .screenPadding()

            Spacer()
        }
    }
}

/// The premium panic tool: 4-4 breathing circle, urge timer, and rotating
/// encouragement. Surviving the urge pays a small gem reward.
struct PanicModeView: View {
    @Environment(GemStore.self) private var gems
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var elapsed = 0
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    /// 4-4-4 breathing: inhale, hold full, exhale.
    private enum BreathPhase: Int, CaseIterable {
        case breatheIn, hold, breatheOut

        var label: String {
            switch self {
            case .breatheIn:  "Breathe in"
            case .hold:       "Hold"
            case .breatheOut: "Breathe out"
            }
        }
        /// Lungs full while inhaling and holding; empty on the exhale.
        var lungsFull: Bool { self != .breatheOut }
    }

    private var phase: BreathPhase {
        BreathPhase.allCases[(elapsed / 4) % BreathPhase.allCases.count]
    }

    /// Urge-focused lines, rotated every 8 seconds.
    private let encouragements = [
        "The urge is temporary. Your streak isn't.",
        "Urges peak and pass within minutes. Outlast this one.",
        "You've beaten this before. You'll beat it now.",
        "Picture yourself one hour from now, proud you held on.",
        "Breathe. This feeling is your brain rewiring itself."
    ]

    /// If the user has written their own motivations, lead with those —
    /// otherwise fall back to the default encouragement lines.
    private var lines: [String] {
        guard !appState.motivations.isEmpty else { return encouragements }
        return appState.motivations.map { "Your why: \($0.text)" } + encouragements.prefix(2)
    }

    private var timerText: String {
        String(format: "%d:%02d", elapsed / 60, elapsed % 60)
    }

    /// Two full 12s breath cycles before the reward unlocks.
    private let minimumSeconds = 24
    private var canFinish: Bool { elapsed >= minimumSeconds }
    private var safeButtonTitle: String {
        canFinish ? "I'm Safe Now"
                  : String(format: "I'm Safe Now · 0:%02d", minimumSeconds - elapsed)
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Capsule().fill(Theme.Colors.textTertiary).frame(width: 40, height: 5)
                .padding(.top, Theme.Spacing.sm)

            Text("Panic Mode")
                .font(Theme.Typography.title())
                .foregroundStyle(Theme.Colors.textPrimary)

            Text("You're resisting for \(timerText)")
                .font(Theme.Typography.body())
                .foregroundStyle(Theme.Colors.textSecondary)
                .monospacedDigit()

            Spacer()

            ZStack {
                Circle()
                    .fill(Theme.Colors.primary.opacity(0.15))
                    .frame(width: 180, height: 180)
                    .scaleEffect(phase.lungsFull ? 1.35 : 1.0)
                // Gradient ring hugging the halo — soft glow copy underneath.
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [Theme.Colors.primary, Theme.Colors.green,
                                     Color(hex: 0x8B7BF0), Theme.Colors.primary],
                            center: .center),
                        lineWidth: 6
                    )
                    .frame(width: 180, height: 180)
                    .blur(radius: 8)
                    .scaleEffect(phase.lungsFull ? 1.35 : 1.0)
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [Theme.Colors.primary, Theme.Colors.green,
                                     Color(hex: 0x8B7BF0), Theme.Colors.primary],
                            center: .center),
                        lineWidth: 2.5
                    )
                    .frame(width: 180, height: 180)
                    .scaleEffect(phase.lungsFull ? 1.35 : 1.0)
                Circle()
                    .fill(Theme.Colors.primaryGradient)
                    .frame(width: 120, height: 120)
                    .scaleEffect(phase.lungsFull ? 1.25 : 0.9)
                Text(phase.label)
                    .font(Theme.Typography.headline())
                    .foregroundStyle(.white)
                    .transaction { $0.animation = nil }   // label swaps instantly; only the circle breathes
            }
            .animation(.easeInOut(duration: 4), value: phase.lungsFull)
            .frame(height: 250)

            Text(lines[(elapsed / 8) % lines.count])
                .font(Theme.Typography.cardTitle())
                .foregroundStyle(Theme.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .screenPadding()
                .animation(.easeInOut(duration: 0.3), value: elapsed / 8)

            Spacer()

            // Reward tracks actually riding out the urge — locked for the first
            // two full breath cycles. Swipe-to-dismiss always works; never trap
            // a user in panic mode.
            PrimaryButton(title: safeButtonTitle, trailingEmoji: canFinish ? "💪" : nil) {
                gems.award(25)
                gems.recordAchievement("breathing")
                Haptics.success()
                dismiss()
            }
            .opacity(canFinish ? 1 : 0.5)
            .disabled(!canFinish)
            .screenPadding()
            .padding(.bottom, Theme.Spacing.lg)
        }
        .onReceive(timer) { _ in
            elapsed += 1
        }
    }
}

/// Red rotating-siren icon with light rays.
struct SirenIcon: View {
    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                Capsule()
                    .fill(Color(hex: 0xF08A5D))
                    .frame(width: 3, height: 14)
                    .offset(y: -40)
                    .rotationEffect(.degrees(Double(i) / 8 * 360))
            }
            Image(systemName: "light.beacon.max.fill")
                .font(.system(size: 44))
                .foregroundStyle(Theme.Colors.red)
        }
        .frame(width: 100, height: 100)
    }
}

#Preview { PanicSheet().environment(GemStore()).environment(AppState()) }
