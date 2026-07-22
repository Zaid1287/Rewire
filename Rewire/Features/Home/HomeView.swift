import SwiftUI
import Combine

/// Home tab — RonLab Void scene: goal pill, hero streak numeral with live
/// remainder, 60-day morse strip, best-run/recovery glass cards, milk panic
/// capsule. Three-state hero (first victory / post-slip / ongoing run) kept
/// from the flow redesign.
struct HomeView: View {
    @Environment(StreakStore.self) private var streak
    @Environment(GemStore.self) private var gems

    @State private var path: [HomeRoute] = []
    @State private var showStreakSheet = false
    @State private var showPanicSheet = false
    @State private var showSlipLog = false
    @State private var showCheckIn = false
    @State private var showRewardBox = false
    /// Drives the offer countdown re-render; the deadline itself lives in GemStore.
    @State private var now = Date()
    private let offerTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    enum HomeRoute: Hashable { case setGoal, addDays, challenge }

    /// The current run's time past its whole-day count, e.g. "19h 34m 08s".
    private var subDayRemainderText: String {
        let rem = Int(streak.elapsed) % 86_400
        return String(format: "%dh %02dm %02ds", rem / 3600, (rem % 3600) / 60, rem % 60)
    }

    /// Seconds left on the one-time special offer (0 once expired or never started).
    private var offerRemaining: Int {
        guard let deadline = gems.offerDeadline else { return 0 }
        return max(0, Int(deadline.timeIntervalSince(now)))
    }

    /// 90-day rewiring fraction (same basis as the Recovery gauge).
    private var recoveryPercent: Int {
        min(100, Int(streak.elapsed / 86_400 / 90 * 100))
    }

    /// Last 60 days as rhythm: dashes for clean runs, red dots for relapses.
    private var morseMarks: [MorseMark] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let relapseDays = Set(streak.events.filter { $0.type == .relapse }
            .map { cal.startOfDay(for: $0.date) })
        let days: [Bool?] = (0..<60).reversed().map { offset in
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return !relapseDays.contains(day)
        }
        return MorseStrip.marks(fromDays: days)
    }

    private var relapsesInWindow: Int {
        let cal = Calendar.current
        guard let cutoff = cal.date(byAdding: .day, value: -60, to: Date()) else { return 0 }
        return streak.events.filter { $0.type == .relapse && $0.date >= cutoff }.count
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                SceneBackground(kind: .void)

                ScrollView {
                    VStack(spacing: 0) {
                        goalPill
                        heroSection
                        statCards
                        panicCapsule
                        quietActions
                    }
                    .padding(.top, Theme.Spacing.md)
                    .padding(.bottom, Theme.Spacing.tabBarClearance)
                }
                .collapsesDock()
            }
            .safeAreaInset(edge: .top) { topRow.background { TopFadeScrim() } }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .setGoal:   SetGoalView()
                case .addDays:   AddDaysView()
                case .challenge: WeeklyChallengeView()
                }
            }
            .fullScreenCover(isPresented: $showStreakSheet) { MyStreakSheet() }
            // Full screen with no swipe-to-dismiss: mid-urge, the only exit is
            // "I'm Safe Now" — the crisis tool is free for everyone, no upsell.
            .fullScreenCover(isPresented: $showPanicSheet) { PanicSheet() }
            // Slip Log resets the run only on save, so no "are you sure?" alert
            // is needed — backing out of it costs nothing.
            .fullScreenCover(isPresented: $showSlipLog) { SlipLogFlow() }
            .sheet(isPresented: $showCheckIn) {
                // Frame 3 is a full screen (ruler + question card + buttons);
                // the old .medium detent clipped it.
                CheckInFlow().presentationDetents([.large])
            }
            .fullScreenCover(isPresented: $showRewardBox) { RewardBoxView() }
            .onReceive(offerTimer) { now = $0 }
            .onAppear { if !gems.isPremium { gems.startOfferIfNeeded() } }
        }
        .tint(Theme.Colors.butter)
    }

    // MARK: Top row — brand squircle left, gift right (offer badge)

    private var topRow: some View {
        HStack {
            squircleButton { showStreakSheet = true } content: {
                BrandDots(size: 20, color: Theme.Colors.textHi)
            }
            Spacer()
            squircleButton { showRewardBox = true } content: {
                Image(systemName: "gift")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(Theme.Colors.textHi)
            }
            .overlay(alignment: .topTrailing) {
                if offerRemaining > 0 && !gems.isPremium {
                    Circle().fill(Color(hex: 0xE8352E)).frame(width: 7, height: 7)
                        .offset(x: -9, y: 9)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.screen)
        .padding(.top, Theme.Spacing.xs)
    }

    private func squircleButton(_ action: @escaping () -> Void,
                                @ViewBuilder content: () -> some View) -> some View {
        Button { Haptics.tap(); action() } label: {
            content()
                .frame(width: 46, height: 46)
                .background(Color.white.opacity(0.06),
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
        }
        .buttonStyle(PressableButtonStyle())
    }

    // MARK: Goal pill

    private var goalPill: some View {
        PillRow(label: "Goal", value: "\(streak.goal.label) clean") { path.append(.setGoal) }
            .screenPadding()
    }

    // MARK: Hero — three states preserved

    @ViewBuilder private var heroSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !streak.hasRecord && streak.currentRunDays == 0 {
                firstVictoryHero
            } else if streak.currentRunDays == 0 {
                postSlipHero
            } else {
                ongoingHero
            }

            // History rhythm appears once there's history to show — a lone
            // dash on day one reads as broken, not minimal.
            if streak.hasRecord || streak.currentRunDays > 0 {
                MorseStrip(marks: morseMarks)
                    .padding(.top, 30)
                morseCaption
                    .font(Theme.Typography.caption())
                    .foregroundStyle(Theme.Colors.textXlo)
                    .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 30)
        .padding(.top, 40)
    }

    private var morseCaption: Text {
        if relapsesInWindow == 0 {
            return Text("Last 60 days · clean line")
        }
        let word = relapsesInWindow == 1 ? "one relapse" : "\(relapsesInWindow) relapses"
        return Text("Last 60 days · ")
            + Text("●").foregroundStyle(Theme.Colors.critical)
            + Text(" \(word)")
    }

    private var ongoingHero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current streak:")
                .font(Theme.Typography.label())
                .foregroundStyle(Theme.Colors.textLo)
            HeroNumeral(value: "\(streak.currentRunDays)",
                        unit: streak.currentRunDays == 1 ? "day" : "days",
                        size: 96)
            HStack(spacing: 12) {
                Text(subDayRemainderText)
                    .font(Theme.Typography.value())
                    .foregroundStyle(Theme.Colors.textHi)
                    .monospacedDigit()
                Text("and counting")
                    .font(Theme.Typography.caption())
                    .foregroundStyle(Theme.Colors.textXlo)
                Spacer()
                Button { path.append(.addDays) } label: {
                    Text("Add days")
                        .font(Theme.Typography.caption())
                        .foregroundStyle(Theme.Colors.textLo)
                        .underline()
                }
            }
            .padding(.top, 6)
        }
    }

    /// Morning after a slip: what *survived* leads; day 0 is demoted.
    private var postSlipHero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Next run: day 1 · still standing:")
                .font(Theme.Typography.label())
                .foregroundStyle(Theme.Colors.textLo)
            HeroNumeral(value: "\(streak.totalCleanDays)", unit: "days kept", size: 96)
            Text("Last night is logged as a pattern, not a verdict.")
                .font(Theme.Typography.subtitle())
                .foregroundStyle(Theme.Colors.textLo)
                .padding(.top, 6)
        }
    }

    /// Brand-new user — first hours, seconds moment.
    private var firstVictoryHero: some View {
        let c = streak.components
        let value = c.hour > 0 ? "\(c.hour)" : "\(max(c.minute, 1))"
        let unit = c.hour > 0 ? (c.hour == 1 ? "hour" : "hours")
                              : (c.minute == 1 ? "minute" : "minutes")
        return VStack(alignment: .leading, spacing: 8) {
            Text("Your first victory:")
                .font(Theme.Typography.label())
                .foregroundStyle(Theme.Colors.textLo)
            HeroNumeral(value: value, unit: unit, size: 96)
            Text("Every hour counts. The streak starts the moment you decide.")
                .font(Theme.Typography.subtitle())
                .foregroundStyle(Theme.Colors.textLo)
                .padding(.top, 6)
        }
    }

    // MARK: Stat cards

    private var statCards: some View {
        HStack(spacing: 12) {
            miniCard(title: "Best run", value: "\(streak.bestRunDays)", unit: "days") {
                showStreakSheet = true
            }
            miniCard(title: "Recovery", value: "\(recoveryPercent)", unit: "%") {
                showStreakSheet = true
            }
        }
        .screenPadding()
        .padding(.top, 26)
    }

    private func miniCard(title: String, value: String, unit: String,
                          action: @escaping () -> Void) -> some View {
        Button { Haptics.tap(); action() } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(Theme.Typography.caption())
                    .foregroundStyle(Theme.Colors.textLo)
                HStack(alignment: .lastTextBaseline, spacing: 5) {
                    Text(value)
                        .font(Theme.Typography.unitSuffix(24))
                        .foregroundStyle(Theme.Colors.textHi)
                        .monospacedDigit()
                    Text(unit)
                        .font(Theme.Typography.caption())
                        .foregroundStyle(Theme.Colors.textXlo)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .overlay(alignment: .topTrailing) {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Theme.Colors.textHi)
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.07), in: Circle())
                    .padding(12)
            }
        }
        .buttonStyle(PressableButtonStyle())
        .smokedGlass(radius: 26)
    }

    // MARK: Panic + quiet actions

    private var panicCapsule: some View {
        Button {
            Haptics.warning()
            showPanicSheet = true
        } label: {
            HStack(spacing: 10) {
                Circle().fill(Theme.Colors.critical).frame(width: 8, height: 8)
                Text("Panic — I need help now")
            }
            .font(Theme.Typography.button())
            .foregroundStyle(Color(hex: 0x141416))
            .frame(maxWidth: .infinity)
            .frame(height: 62)
            .background(Color(hex: 0xF3F2EF), in: Capsule())
            .shadow(color: .black.opacity(0.35), radius: 18, y: 8)
        }
        .buttonStyle(PressableButtonStyle())
        .screenPadding()
        .padding(.top, 26)
    }

    private var quietActions: some View {
        HStack(spacing: 12) {
            QuietGlassButton(title: streak.checkedInToday ? "Checked in ✓" : "Check-in") {
                showCheckIn = true
            }
            QuietGlassButton(title: "Log a slip") { showSlipLog = true }
        }
        .screenPadding()
        .padding(.top, 12)
    }
}

/// The 3-dot brand cluster mark.
struct BrandDots: View {
    var size: CGFloat = 20
    var color: Color = Theme.Colors.textHi

    var body: some View {
        Canvas { ctx, _ in
            let s = size / 20
            for (x, y, r) in [(8.0, 7.0, 3.4), (14.4, 12.6, 2.1), (7.4, 14.6, 1.5)] {
                ctx.fill(Path(ellipseIn: CGRect(x: (x - r) * s, y: (y - r) * s,
                                                width: r * 2 * s, height: r * 2 * s)),
                         with: .color(color))
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    HomeView()
        .environment(StreakStore())
        .environment(GemStore())
}
