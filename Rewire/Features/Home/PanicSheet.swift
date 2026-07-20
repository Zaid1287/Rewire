import SwiftUI

/// Panic Button (flow-redesign Phase 3, plan §5 + decision #2).
/// The crisis tool is FREE for every user — guided breathing, urge timer,
/// rotating encouragement, and the "I'm Safe Now" exit. Premium extends it
/// with urge-wave mode: the ~10-minute wave visualization and per-minute
/// scaled rewards. There is NO upsell anywhere in the crisis path — the only
/// premium pitch lives in the post-crisis debrief, after the user is safe.
struct PanicSheet: View {
    @Environment(GemStore.self) private var gems

    var body: some View {
        PanicModeView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Colors.background)
            .onAppear {
                gems.recordAchievement("panic")
                Analytics.capture("panic_opened")
            }
    }
}

/// The panic tool: breathing + urge timer (free), urge-wave mode (premium),
/// ending in a post-crisis debrief. Riding out the urge pays a gem reward —
/// flat for free, per-minute for premium.
struct PanicModeView: View {
    @Environment(GemStore.self) private var gems
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var elapsed = 0
    /// One-beat scale pop when the reward button unlocks at 24s.
    @State private var unlockPulse = false
    /// Explicit breath state, starts DEFLATED — the very first motion the user
    /// sees is the inhale expanding. (Deriving scale straight from the phase
    /// rendered the circle already-full, so the first visible motion was the
    /// 8s exhale shrinking — backwards.)
    @State private var lungsInflated = false
    /// Crisis screen vs post-crisis debrief.
    @State private var stage: Stage = .riding
    @State private var earned = 0
    @State private var whatHelped: String?
    @State private var showPaywall = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    enum Stage { case riding, debrief }

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

    /// Breathing scale ranges — shrunk (not removed) under Reduce Motion:
    /// the pacing is the feature, the large oscillation is the vestibular problem.
    private var haloScale: CGFloat {
        lungsInflated ? (reduceMotion ? 1.1 : 1.35) : 1.0
    }
    private var coreScale: CGFloat {
        lungsInflated ? (reduceMotion ? 1.05 : 1.25) : (reduceMotion ? 0.95 : 0.9)
    }

    /// Animate toward the current phase's lung state (inhale/hold = inflated,
    /// exhale = deflated). One 4s ease per transition, matching the 4-4-4 pace.
    private func syncBreath() {
        let inflate = phase.lungsFull
        guard inflate != lungsInflated else { return }
        withAnimation(.easeInOut(duration: 4)) { lungsInflated = inflate }
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

    private var minutesRidden: Int { max(1, elapsed / 60) }
    /// Premium rides the wave: +10 gems per minute held, capped at the 15-min
    /// wave end. Free keeps the flat reward.
    private var rewardIfSafeNow: Int {
        gems.isPremium ? min(150, minutesRidden * 10) : 25
    }

    var body: some View {
        ZStack {
            Group {
                switch stage {
                case .riding:  riding
                case .debrief: debrief
                }
            }
            .transition(.push(forward: true))
        }
        .animation(Theme.Motion.enter, value: stage)
        .onAppear { syncBreath() }   // first motion = the inhale, immediately
        .onReceive(timer) { _ in
            guard stage == .riding else { return }
            elapsed += 1
            syncBreath()
            // The earned moment: haptic + one spring pulse when the reward unlocks.
            if elapsed == minimumSeconds {
                Haptics.success()
                if !reduceMotion {
                    withAnimation(Theme.Motion.emphasized) { unlockPulse = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        withAnimation(Theme.Motion.emphasized) { unlockPulse = false }
                    }
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallSheet().presentationDetents([.medium, .large])
        }
    }

    // MARK: Riding the urge (crisis screen — no upsell, ever)

    private var riding: some View {
        VStack(spacing: Theme.Spacing.lg) {
            SheetChrome(title: "Panic Mode")

            Text(gems.isPremium
                 ? "You're riding minute \(minutesRidden) of the wave"
                 : "You're resisting for \(timerText)")
                .font(Theme.Typography.body())
                .foregroundStyle(Theme.Colors.textSecondary)
                .monospacedDigit()

            Spacer()

            // The breathing circle is the centre of attention on BOTH tiers —
            // it's the thing that actually calms someone down. Premium's wave
            // rides below it as secondary context, never above it.
            breathingCircle

            if gems.isPremium {
                UrgeWaveView(elapsed: elapsed)
                    .screenPadding()

                Text("💎 +10 gems for every minute you hold")
                    .font(Theme.Typography.bodyMedium())
                    .foregroundStyle(Theme.Colors.star)
            }

            // .id + .transition drive the crossfade — a bare .animation on a
            // Text can't animate a string swap (not animatable), it just snaps.
            ZStack {
                Text(lines[(elapsed / 8) % lines.count])
                    .font(Theme.Typography.cardTitle())
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .screenPadding()
                    .id(elapsed / 8)
                    .transition(.opacity)
            }
            .animation(Theme.Motion.enter, value: elapsed / 8)

            Spacer()

            // Reward tracks actually riding out the urge — locked for the
            // first two full breath cycles. In panic mode (full screen,
            // no swipe-to-dismiss) this button is the only way out, by design.
            PrimaryButton(title: safeButtonTitle, trailingEmoji: canFinish ? "💪" : nil) {
                earned = rewardIfSafeNow
                gems.award(earned)
                gems.recordAchievement("breathing")
                Haptics.success()
                Analytics.capture("panic_survived")   // duration stays private
                stage = .debrief
            }
            .opacity(canFinish ? 1 : 0.5)
            .scaleEffect(unlockPulse ? 1.03 : 1)
            .disabled(!canFinish)
            .animation(Theme.Motion.enter, value: canFinish)
            .screenPadding()
            .padding(.bottom, Theme.Spacing.lg)
        }
    }

    /// The free tier's full-size breathing pacer.
    private var breathingCircle: some View {
        ZStack {
            Circle()
                .fill(Theme.Colors.primary.opacity(0.15))
                .frame(width: 180, height: 180)
                .scaleEffect(haloScale)
            // Gradient ring hugging the halo — soft glow copy underneath.
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [Theme.Colors.primary, Theme.Colors.green,
                                 Theme.Colors.purple, Theme.Colors.primary],
                        center: .center),
                    lineWidth: 6
                )
                .frame(width: 180, height: 180)
                .blur(radius: 8)
                .scaleEffect(haloScale)
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [Theme.Colors.primary, Theme.Colors.green,
                                 Theme.Colors.purple, Theme.Colors.primary],
                        center: .center),
                    lineWidth: 2.5
                )
                .frame(width: 180, height: 180)
                .scaleEffect(haloScale)
            // Soft glowing orb, not a solid disc — a radial fade with a thin
            // rim reads as breath and light, which is what calms someone down.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.Colors.primary.opacity(0.85),
                                 Theme.Colors.primary.opacity(0.35),
                                 Theme.Colors.primary.opacity(0.0)],
                        center: .center, startRadius: 8, endRadius: 62)
                )
                .frame(width: 124, height: 124)
                .scaleEffect(coreScale)
            Circle()
                .stroke(Theme.Colors.primary.opacity(0.55), lineWidth: 1.5)
                .frame(width: 108, height: 108)
                .scaleEffect(coreScale)
            Text(phase.label)
                .font(Theme.Typography.headline())
                .foregroundStyle(Theme.Colors.textPrimary)
                .transaction { $0.animation = nil }   // label swaps instantly; only the circle breathes
        }
        .frame(height: 250)
    }

    // MARK: Post-crisis debrief — the only place premium is ever pitched

    private var debrief: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.white, Theme.Colors.green)
                .transition(.scale(scale: 0.92).combined(with: .opacity))

            VStack(spacing: Theme.Spacing.sm) {
                Text("You made it through.")
                    .font(Theme.Typography.title())
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text("\(minutesRidden) minute\(minutesRidden == 1 ? "" : "s") ridden. The wave broke — you didn't.")
                    .font(Theme.Typography.body())
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .screenPadding()

            Text("💎 +\(earned) gems earned")
                .font(Theme.Typography.headline())
                .foregroundStyle(Theme.Colors.star)

            ChipGroup(title: "What helped most?",
                      options: ["Breathing", "My motivations", "The urge timer"],
                      selection: $whatHelped)
                .screenPadding()

            if !gems.isPremium {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Go further next time")
                        .font(Theme.Typography.headline())
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text("Full wave mode, per-minute rewards, and slip-pattern insights — in Rewire Premium.")
                        .font(Theme.Typography.subtitle())
                        .foregroundStyle(Theme.Colors.textSecondary)
                    PrimaryButton(title: "See Premium") { showPaywall = true }
                        .padding(.top, Theme.Spacing.xs)
                }
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.primary.opacity(0.10),
                            in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .stroke(Theme.Colors.primary.opacity(0.4), lineWidth: 1))
                .screenPadding()
            }

            Spacer()

            Button {
                if whatHelped != nil { Analytics.capture("panic_debrief_helped") }
                Haptics.tap()
                dismiss()
            } label: {
                Text("Done")
                    .font(Theme.Typography.button())
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Theme.Colors.surface2, in: Capsule())
            }
            .buttonStyle(PressableButtonStyle())
            .screenPadding()
            .padding(.bottom, Theme.Spacing.lg)
        }
    }
}

/// The ~10-minute urge wave (premium): a crest the user's dot rides in real
/// time. Seeing your position on a curve that *ends* reframes the urge as
/// finite — the design answer to "urges peak and pass" (Reddit finding #5).
struct UrgeWaveView: View {
    let elapsed: Int   // seconds
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The wave spans 15 minutes; the dot clamps at the end.
    private let total: Double = 15 * 60

    /// Normalized wave height (0 = flat, 1 = crest) — gaussian peaking at
    /// t = 0.4 (~minute 6 of 15).
    private func crest(_ t: Double) -> Double {
        exp(-pow(t - 0.4, 2) / (2 * 0.18 * 0.18))
    }
    private func point(_ t: Double, in size: CGSize) -> CGPoint {
        CGPoint(x: t * size.width,
                y: (0.88 - 0.72 * crest(t)) * size.height)
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            GeometryReader { geo in
                let t = min(1, Double(elapsed) / total)
                ZStack {
                    Path { p in
                        p.move(to: point(0, in: geo.size))
                        for step in 1...60 {
                            p.addLine(to: point(Double(step) / 60, in: geo.size))
                        }
                    }
                    .stroke(
                        LinearGradient(colors: [Theme.Colors.primary, Theme.Colors.flame, Theme.Colors.green],
                                       startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )

                    Text("crest ~min 6")
                        .font(Theme.Typography.caption())
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .position(point(0.4, in: geo.size).applying(.init(translationX: 0, y: -14)))
                    Text("it passes")
                        .font(Theme.Typography.caption())
                        .foregroundStyle(Theme.Colors.green)
                        .position(point(0.93, in: geo.size).applying(.init(translationX: 0, y: -14)))

                    Circle()
                        .fill(Theme.Colors.textPrimary)
                        .frame(width: 14, height: 14)
                        .position(point(t, in: geo.size))
                        .animation(reduceMotion ? nil : .linear(duration: 1), value: elapsed)
                }
            }
            .frame(height: 90)

            HStack {
                Text("min 0")
                Spacer()
                Text("most urges are done by min 10–15")
            }
            .font(Theme.Typography.caption())
            .foregroundStyle(Theme.Colors.textTertiary)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
    }
}

#Preview { PanicSheet().environment(GemStore()).environment(AppState()) }
