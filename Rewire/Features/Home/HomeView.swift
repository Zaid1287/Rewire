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
    @State private var showRelapseAlert = false
    @State private var showRelapseFlow = false
    @State private var showReportFlow = false
    @State private var showRewardBox = false
    @State private var showPaywall = false
    @State private var selectedPlan: Plan = SampleData.plans[1]
    @State private var offer = OfferClock()

    enum HomeRoute: Hashable { case setGoal, addDays, challenge }

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
                        planSection
                    }
                    .padding(.top, Theme.Spacing.md)
                    .padding(.bottom, 120)
                }

                // Floating special-offer countdown — an upsell, so premium users
                // never see it and it leaves once the offer runs out.
                if !gems.isPremium && !offer.expired {
                    OfferBanner(minutes: offer.minutes, seconds: offer.seconds)
                        .offset(x: Theme.Spacing.md, y: 300)
                        .allowsHitTesting(false)
                }
            }
            .safeAreaInset(edge: .top) {
                HomeStatHeader(shieldPercent: 5,
                               streakText: "\(streak.components.minute)m",
                               gems: gems.gems,
                               onGiftTap: { showRewardBox = true })
                    .background(Theme.Colors.background)
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
            .sheet(isPresented: $showPanicSheet) {
                PanicSheet().presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showPaywall) {
                PaywallSheet().presentationDetents([.medium, .large])
            }
            .fullScreenCover(isPresented: $showRelapseFlow) { RelapseFlow() }
            .fullScreenCover(isPresented: $showReportFlow) { DailyReportFlow() }
            .fullScreenCover(isPresented: $showRewardBox) { RewardBoxView() }
            .overlay {
                if showRelapseAlert {
                    RewireAlert(
                        title: "Relapse",
                        message: "Have you relapsed recently?",
                        cancelTitle: "Cancel",
                        confirmTitle: "Yes, relapsed.",
                        onCancel: { showRelapseAlert = false },
                        onConfirm: {
                            showRelapseAlert = false
                            showRelapseFlow = true
                        }
                    )
                }
            }
            .onReceive(offer.timer) { _ in offer.tick() }
        }
        .tint(Theme.Colors.green)
    }

    // MARK: Sections

    private var heroSection: some View {
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
                                 value: "0", unit: "hours") { showStreakSheet = true }
                    ShortcutCard(symbol: "flame.fill", title: "Streak", tint: Theme.Colors.flame,
                                 value: "\(streak.components.minute)", unit: "minutes") { showStreakSheet = true }
                }
                HStack(spacing: Theme.Spacing.md) {
                    WideActionCard(symbol: "arrow.uturn.backward", title: "Relapse",
                                   caption: "I've relapsed.") { showRelapseAlert = true }
                    WideActionCard(symbol: "square.and.pencil", title: "Daily Report", count: 1,
                                   caption: "How was your day?") { showReportFlow = true }
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

    private var weekSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            SectionHeader(title: "This Week") {
                LinkButton(title: "Detail") { showStreakSheet = true }
            }
            Button { Haptics.tap(); path.append(.challenge) } label: {
                Card {
                    WeekStrip(filledIndex: 5)   // Friday highlighted in the shots
                }
            }
            .buttonStyle(PressableButtonStyle())
        }
        .screenPadding()
    }

    private var planSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.sm) {
                TagBadge(kind: .plus)
                Text("Choose your plan")
                    .font(Theme.Typography.title())
                    .foregroundStyle(Theme.Colors.textPrimary)
            }
            VStack(spacing: 0) {
                ForEach(Array(SampleData.plans.enumerated()), id: \.element.id) { idx, plan in
                    PlanRow(plan: plan, isSelected: selectedPlan == plan) { selectedPlan = plan }
                    if idx < SampleData.plans.count - 1 { RowDivider(inset: Theme.Spacing.lg) }
                }
            }
            .background(Theme.Colors.surface.opacity(0.4),
                        in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.lg).stroke(Theme.Colors.divider, lineWidth: 1))

            PrimaryButton(title: "Unlock Premium", trailingEmoji: "🙌") { showPaywall = true }
        }
        .screenPadding()
    }
}

/// Lightweight countdown model for the special-offer banner.
@Observable
final class OfferClock {
    var minutes = 5
    var seconds = 56
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var expired: Bool { minutes == 0 && seconds == 0 }

    func tick() {
        if seconds > 0 { seconds -= 1 }
        else if minutes > 0 { minutes -= 1; seconds = 59 }
    }
}

#Preview {
    HomeView()
        .environment(StreakStore())
        .environment(GemStore())
}
