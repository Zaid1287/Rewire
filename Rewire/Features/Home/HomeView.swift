import SwiftUI
import Combine

/// Home tab (IMG_5440 / 5441): live streak hero, timer grid, goal progress,
/// shortcut actions, weekly strip, and the plan upsell — with a floating
/// special-offer countdown clinging to the right edge.
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

    /// Top streak unit for the header pill: "2d", "18h", "44m" — never just
    /// the minute component of a multi-day streak.
    private var compactStreakText: String {
        let c = streak.components
        if c.year > 0 || c.month > 0 || c.day > 0 {
            return "\(c.year * 365 + c.month * 30 + c.day)d"
        }
        if c.hour > 0 { return "\(c.hour)h" }
        return "\(c.minute)m"
    }

    /// Rough "time not spent watching" heuristic: one hour per full day clean.
    private var savedHours: Int { Int(streak.elapsed / 86_400) }

    /// The current run's time past its whole-day count, e.g. "19h 34m 08s" —
    /// the live-ticking tail under the day hero.
    private var subDayRemainderText: String {
        let rem = Int(streak.elapsed) % 86_400
        return String(format: "%dh %02dm %02ds", rem / 3600, (rem % 3600) / 60, rem % 60)
    }

    /// Seconds left on the one-time special offer (0 once expired or never started).
    private var offerRemaining: Int {
        guard let deadline = gems.offerDeadline else { return 0 }
        return max(0, Int(deadline.timeIntervalSince(now)))
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .topTrailing) {
                ScrollView {
                    VStack(spacing: Theme.Spacing.xxl) {
                        heroSection
                        liveTimerSection
                        progressSection
                        shortcutsSection
                        weekSection
                    }
                    .padding(.top, Theme.Spacing.md)
                    .padding(.bottom, Theme.Spacing.tabBarClearance)
                }
                .collapsesDock()

                // Floating special-offer countdown — an upsell, so premium users
                // never see it. Deadline is persisted: the offer runs once per
                // install and never comes back after expiring.
                if !gems.isPremium && offerRemaining > 0 {
                    OfferBanner(minutes: offerRemaining / 60, seconds: offerRemaining % 60)
                        .offset(x: Theme.Spacing.md, y: 300)
                        .allowsHitTesting(false)
                }
            }
            .safeAreaInset(edge: .top) {
                // Floating glass capsule; the scrim fades scrolling content out
                // before the status bar instead of a solid bar.
                HomeStatHeader(shieldPercent: max(1, min(100, Int(streak.progress * 100))),
                               streakText: compactStreakText,
                               gems: gems.gems,
                               showsWarning: streak.progress < 1,
                               onGiftTap: { showRewardBox = true })
                    .background { TopFadeScrim() }
            }
            .background(Theme.Colors.background)
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
            .fullScreenCover(isPresented: $showPanicSheet) {
                PanicSheet()
            }
            // Slip Log resets the run only on save, so no "are you sure?" alert
            // is needed — backing out of it costs nothing.
            .fullScreenCover(isPresented: $showSlipLog) { SlipLogFlow() }
            .sheet(isPresented: $showCheckIn) {
                CheckInFlow().presentationDetents([.medium])
            }
            .fullScreenCover(isPresented: $showRewardBox) { RewardBoxView() }
            .onReceive(offerTimer) { now = $0 }
            .onAppear { if !gems.isPremium { gems.startOfferIfNeeded() } }
        }
        .tint(Theme.Colors.green)
    }

    // MARK: Sections

    /// Home hero, two-layer streak model (flow-redesign Phase 1). Three states:
    /// - brand-new user (no days, no banked history): the original "first
    ///   victory" seconds moment, untouched — nothing to record yet.
    /// - morning after a slip (run at day 0 but history exists): lead with what
    ///   *survived* ("Still 47."), demote day 0. The anti-"slap in the face" screen.
    /// - an ongoing run: the day count is the hero, with the record strip below.
    @ViewBuilder private var heroSection: some View {
        if !streak.hasRecord && streak.currentRunDays == 0 {
            firstVictoryHero
        } else {
            VStack(spacing: Theme.Spacing.lg) {
                FlameMark(size: 88)
                if streak.currentRunDays == 0 {
                    // Post-slip: what survived leads; day 0 lives in the flame pill.
                    Text("DAY 1 OF YOUR NEXT RUN").sectionHeaderStyle()
                    Text("Still \(streak.totalCleanDays).")
                        .font(Theme.Typography.bigNumber())
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text("Last night is logged as a pattern, not a verdict.")
                        .font(Theme.Typography.body())
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .screenPadding()
                } else {
                    Text("CURRENT RUN").sectionHeaderStyle()
                    Text("\(streak.currentRunDays) \(streak.currentRunDays == 1 ? "day" : "days")")
                        .font(Theme.Typography.bigNumber())
                        .foregroundStyle(Theme.Colors.textPrimary)
                    // Live sub-day remainder — the ticking detail, not a repeat
                    // of the day count. (The full Y/M/D/H/M/S grid sits below.)
                    Text("+ \(subDayRemainderText) and counting")
                        .font(Theme.Typography.body())
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .monospacedDigit()
                }
                RecordStrip(totalCleanDays: streak.totalCleanDays,
                            cleanThisMonthPercent: streak.cleanThisMonthPercent,
                            bestRunDays: streak.bestRunDays,
                            caption: streak.currentRunDays == 0 ? "survived the slip ✓" : "only ever grows ↑",
                            highlighted: streak.currentRunDays == 0)
                    .screenPadding()
            }
        }
    }

    /// The untouched brand-new-user moment — matches the first-victory shot.
    private var firstVictoryHero: some View {
        VStack(spacing: Theme.Spacing.md) {
            FlameMark(size: 96)
            Text("Your first victory")
                .font(Theme.Typography.title())
                .foregroundStyle(Theme.Colors.textPrimary)

            // Segmented green "N seconds" pill on a dark track
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.Colors.surface2).frame(width: 340, height: 56)
                Capsule().fill(Theme.Colors.greenMint).frame(width: 340, height: 56)
                    .mask(alignment: .leading) {
                        Capsule().frame(width: 300, height: 56)
                    }
                Text(streak.elapsed.humanShort())
                    .font(Theme.Typography.button())
                    .foregroundStyle(.black)
                    .frame(width: 300, height: 56)
            }
            Text("You're almost there to achieve your first victory in your Rewire challenge.")
                .font(Theme.Typography.body())
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .screenPadding()
        }
    }

    private var liveTimerSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            SectionHeader(title: "Live Timer") {
                HStack(spacing: Theme.Spacing.xs) {
                    LinkButton(title: "Add Days") { path.append(.addDays) }
                }
            }
            .overlay(alignment: .leading) {
                // pulsing red "live" dot next to the header
                Circle().fill(Theme.Colors.red).frame(width: 10, height: 10)
                    .offset(x: 108)
            }

            let c = streak.components
            VStack(spacing: Theme.Spacing.sm) {
                HStack(spacing: Theme.Spacing.sm) {
                    StatTile(value: c.year, unit: "year")
                    StatTile(value: c.month, unit: "month")
                    StatTile(value: c.day, unit: "day")
                }
                HStack(spacing: Theme.Spacing.sm) {
                    StatTile(value: c.hour, unit: "hour")
                    StatTile(value: c.minute, unit: "minute")
                    StatTile(value: c.second, unit: "second")
                }
            }
        }
        .screenPadding()
    }

    private var progressSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            SectionHeader(title: "Progress") {
                LinkButton(title: "Set Goal") { path.append(.setGoal) }
            }
            Card {
                VStack(spacing: Theme.Spacing.md) {
                    HStack {
                        Image(systemName: "checkmark").foregroundStyle(Theme.Colors.textPrimary)
                        Text("Try to reach your \(streak.goal.label) goal.")
                            .font(Theme.Typography.body())
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Spacer()
                        Text(streak.progressPercentText)
                            .font(Theme.Typography.body())
                            .foregroundStyle(Theme.Colors.textPrimary)
                    }
                    ProgressBarView(value: streak.progress, height: 10)
                }
            }
        }
        .screenPadding()
    }

    private var shortcutsSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            SectionHeader("Shortcuts")
            VStack(spacing: Theme.Spacing.md) {
                HStack(spacing: Theme.Spacing.md) {
                    ShortcutCard(symbol: "clock", title: "Saved Time", tint: Theme.Colors.green,
                                 value: "\(savedHours)", unit: "hours") { showStreakSheet = true }
                    ShortcutCard(symbol: "flame.fill", title: "Streak", tint: Theme.Colors.flame,
                                 value: "\(streak.components.minute)", unit: "minutes") { showStreakSheet = true }
                }
                HStack(spacing: Theme.Spacing.md) {
                    WideActionCard(symbol: "arrow.uturn.backward", title: "Log a Slip",
                                   caption: "It happens. Log it.") { showSlipLog = true }
                    WideActionCard(symbol: "square.and.pencil", title: "Check-in", count: 1,
                                   caption: "How was today?") { showCheckIn = true }
                }
                Button {
                    Haptics.warning()
                    showPanicSheet = true
                } label: {
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "exclamationmark.octagon")
                            .foregroundStyle(Theme.Colors.flame)
                        Text("Panic Button")
                            .font(Theme.Typography.cardTitle())
                            .foregroundStyle(Theme.Colors.flame)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.lg)
                    .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .screenPadding()
    }

    /// This week's Sun–Sat state, derived from real report/relapse dates.
    /// Relapse wins over report; a plain "today" dot only shows when today
    /// has neither.
    private var weekStates: [WeekStrip.DayState] {
        let cal = Calendar.current
        let today = Date()
        // Sun-first week start, independent of the calendar's locale firstWeekday
        // (WeekStrip's headers are always Sun…Sat).
        let weekday = cal.component(.weekday, from: today)   // 1 = Sun … 7 = Sat
        guard let weekStart = cal.date(byAdding: .day, value: -(weekday - 1), to: cal.startOfDay(for: today)) else {
            return Array(repeating: .none, count: 7)
        }
        let reportDays = Set(streak.reports.map { cal.startOfDay(for: $0.date) })
        let relapseDays = Set(streak.events.filter { $0.type == .relapse }.map { cal.startOfDay(for: $0.date) })

        return (0..<7).map { offset in
            guard let day = cal.date(byAdding: .day, value: offset, to: weekStart) else { return .none }
            let start = cal.startOfDay(for: day)
            if relapseDays.contains(start) { return .relapse }
            if reportDays.contains(start) { return .report }
            if cal.isDate(start, inSameDayAs: cal.startOfDay(for: today)) { return .today }
            return .none
        }
    }

    private var weekSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            SectionHeader(title: "This Week") {
                LinkButton(title: "Detail") { showStreakSheet = true }
            }
            Button { Haptics.tap(); path.append(.challenge) } label: {
                Card {
                    WeekStrip(states: weekStates)
                }
            }
            .buttonStyle(PressableButtonStyle())
        }
        .screenPadding()
    }

}

#Preview {
    HomeView()
        .environment(StreakStore())
        .environment(GemStore())
}
