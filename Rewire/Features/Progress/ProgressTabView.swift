import SwiftUI

/// Progress tab (flow-redesign Phase 4, plan §1): Recovery + History merged —
/// "how am I doing?" is one mental model. Recovery ring, badges/levels
/// collection, the two counts the old Stats tab owned, streak history, and
/// events — one Recovery tab instead of two that answered the same question
/// (with slip undo), plus the floating Add Event button.
/// Named ProgressTabView because SwiftUI owns `ProgressView`.
struct ProgressTabView: View {
    enum Route: Hashable { case badges, levels, streakDetail(Int) }
    @Environment(AppState.self) private var appState
    @Environment(GemStore.self) private var gems
    @Environment(StreakStore.self) private var streak
    @State private var path: [Route] = []
    @State private var showAddEvent = false
    @State private var showDeleteAlert = false

    /// Clean days in the last 90, from the same record the Home strip and the
    /// widget use. Replaces a "% rewired" figure against a 90-day "rewire
    /// window": we cannot evidence a claim about anyone's neural pathways, and
    /// reviewers punish invented percentages harder than anything else in the
    /// corpus (13 such complaints average 1.54★, 85% of them 1–2★ —
    /// *"Have fun with your pseudoscientific woo"*). This counts days.
    private var cleanInLast90: Int { streak.cleanDayCount(inLast: 90) }
    /// Days actually tracked — a fresh install reads "1 / 1", never "90 / 90".
    private var trackedWindow: Int { streak.trackedDayCount(inLast: 90) }

    /// Earned-but-unclaimed badges — the red bubble on the Badges card.
    private var unclaimedBadges: Int {
        BadgeProgress.unclaimedCount(appState: appState, streak: streak, gems: gems)
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottomTrailing) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                            recoveryHeader
                            statPair
                            collection
                            streaksSection
                            eventsSection
                            historyGate
                            patternGate
                            easier
                        }
                        .screenPadding()
                        .padding(.top, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.tabBarClearance + 20)
                    }
                    .collapsesDock()

                    Button {
                        Haptics.tap(); showAddEvent = true
                    } label: {
                        HStack(spacing: Theme.Spacing.xs) {
                            Image(systemName: "plus")
                            Text("Add Event").font(Theme.Typography.button())
                        }
                        .foregroundStyle(Color(hex: 0x141416))
                        .padding(.horizontal, Theme.Spacing.lg)
                        .frame(height: 54)
                        .background(Theme.Colors.butter, in: Capsule())
                        .shadow(color: .black.opacity(0.3), radius: 14, y: 6)
                    }
                    .buttonStyle(PressableButtonStyle())
                    .padding(.trailing, Theme.Spacing.lg)
                    .padding(.bottom, 110)
            }
            // Floating glass header; content scrolls underneath, fading out
            // via the scrim before it reaches the status bar.
            .safeAreaInset(edge: .top) {
                NavHeader(title: "Progress") {
                    Button { Haptics.tap(); showDeleteAlert = true } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .frame(width: 44, height: 44)
                            .liquidGlass(in: Circle())
                    }
                }
                .background { TopFadeScrim() }
            }
            .background { SceneBackground(kind: .amberFog) }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .badges:      BadgesView()
                case .levels:      LevelsView()
                case .streakDetail(let i): StreakDetailView(index: i)
                }
            }
            .sheet(isPresented: $showAddEvent) {
                AddEventView().presentationDetents([.medium])
            }
            .rewireAlert(isPresented: showDeleteAlert) {
                RewireAlert(
                    title: "Delete streaks?",
                    message: "This will remove all completed streaks. This can't be undone.",
                    cancelTitle: "Cancel",
                    confirmTitle: "Delete",
                    onCancel: { showDeleteAlert = false },
                    onConfirm: {
                        showDeleteAlert = false
                        for s in streak.streaks where !s.isOngoing { streak.deleteStreak(s) }
                    }
                )
            }
        }
        .tint(Theme.Colors.butter)
    }

    // MARK: Recovery sections (from the old Recovery tab)

    private var recoveryHeader: some View {
        VStack(spacing: 10) {
            ZStack {
                TickRing(count: 66,
                         activeFraction: Double(cleanInLast90) / Double(trackedWindow),
                         startAngle: .degrees(135), sweep: .degrees(270),
                         tickLength: 16,
                         inactiveColor: .white.opacity(0.22),
                         activeColor: .white.opacity(0.9),
                         positionDot: Theme.Colors.butter)
                    .frame(width: 250, height: 250)
                VStack(spacing: 2) {
                    HeroNumeral(value: "\(cleanInLast90)", unit: "/ \(trackedWindow)", size: 76)
                    Text("clean days")
                        .font(Theme.Typography.label())
                        .foregroundStyle(Theme.Colors.textLo)
                }
            }
            // Deliberately a different measure from the Home numeral: that one
            // is the run you're on, this is how much of the last three months
            // held. A slip dents this instead of erasing it.
            Text("Days you stayed clean out of the \(trackedWindow) we've tracked — a slip costs one day here, not the whole picture.")
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Colors.textXlo)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.lg)
        }
        .frame(maxWidth: .infinity)
    }

    /// Urges ridden out — every logged event that isn't a relapse. Was the one
    /// number the old Stats tab owned outright.
    private var urgesBeaten: Int {
        streak.events.filter { $0.type != .relapse }.count
    }

    /// Check-ins where nothing was flagged. The other number worth keeping.
    private var cleanCheckIns: Int {
        streak.reports.filter { !$0.watchedPorn && !$0.masturbated && !$0.relapsed }.count
    }

    /// The two counts the Stats tab existed for. Its clean-days gauge duplicated
    /// the ring above, and its check-ins barcode duplicated Home's morse strip,
    /// so only these came across.
    private var statPair: some View {
        HStack(spacing: 12) {
            countCard("Urges beaten", urgesBeaten)
            countCard("Clean check-ins", cleanCheckIns)
        }
    }

    private func countCard(_ title: String, _ value: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(Theme.Typography.label())
                .foregroundStyle(Theme.Colors.textLo)
            Text("\(value)")
                .font(Theme.Typography.unitSuffix(34))
                .foregroundStyle(Theme.Colors.textHi)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .smokedGlass(radius: 24)
    }

    private var collection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader("My Collection")
            HStack(spacing: Theme.Spacing.md) {
                collectionCard(icon: "rosette", iconColor: Theme.Colors.textLo,
                               title: "Badges",
                               badge: unclaimedBadges == 0 ? nil : unclaimedBadges,
                               value: "\(gems.claimedBadges.count)", unit: "badges") {
                    path.append(.badges)
                }
                collectionCard(icon: "trophy", iconColor: Theme.Colors.textLo,
                               title: "Levels",
                               badge: nil,
                               value: SampleData.level(forDays: streak.bestRunDays).name,
                               unit: nil) {
                    path.append(.levels)
                }
            }
        }
    }

    private func collectionCard(icon: String, iconColor: Color, title: String,
                                badge: Int?, value: String, unit: String?,
                                action: @escaping () -> Void) -> some View {
        Button(action: { Haptics.tap(); action() }) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack(spacing: 6) {
                    Image(systemName: icon).foregroundStyle(iconColor)
                    Text(title.uppercased())
                        .font(Theme.Typography.sectionHeader())
                        .foregroundStyle(iconColor)
                    Image(systemName: "chevron.right").font(.system(size: 11, weight: .bold))
                        .foregroundStyle(iconColor)
                    if let badge { Spacer(); CountBadge(count: badge) }
                }
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value).font(Theme.Typography.statNumber())
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                    if let unit {
                        Text(unit).font(Theme.Typography.body())
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(PressableButtonStyle())
        .smokedGlass(radius: 24)
    }

    private var easier: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader("Make your streaks easier")
            VStack(spacing: 0) {
                ForEach(Array(SampleData.recoveryEasier.enumerated()), id: \.element.id) { idx, item in
                    FeatureRow(item: item).padding(.horizontal, Theme.Spacing.md)
                    if idx < SampleData.recoveryEasier.count - 1 { RowDivider(inset: 64) }
                }
            }
            .smokedGlass(radius: 24)
        }
    }


    // MARK: Premium boundary — history depth

    /// Free users get the last 30 days; Premium gets everything. The cut is by
    /// date rather than by row count so it means the same thing to a heavy
    /// logger and a light one, and so the gate copy ("past 30 days") is
    /// literally true. Free tier still gets every slip they logged in the
    /// window — the raw record is never withheld, only its depth in time.
    private var historyWindowStart: Date? {
        gems.isPremium ? nil : Calendar.current.date(byAdding: .day, value: -30, to: Date())
    }

    private func withinWindow(_ date: Date) -> Bool {
        guard let start = historyWindowStart else { return true }
        return date >= start
    }

    /// Events only. `Streak` carries no date — just index/duration/isOngoing —
    /// so there is no honest way to window it by time, and the streak list is
    /// short anyway. Events are where the history actually accumulates.
    private var visibleEvents: [StreakEvent] {
        streak.events.filter { withinWindow($0.date) }
    }

    /// How much is actually behind the gate. Zero means a new user, who should
    /// not be shown a lock for history they never had.
    private var hiddenHistoryCount: Int { streak.events.count - visibleEvents.count }

    // MARK: History sections (from the old History tab)

    @ViewBuilder private var streaksSection: some View {
        if !streak.streaks.isEmpty {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader("My Streaks")
            VStack(spacing: 0) {
                ForEach(Array(streak.streaks.enumerated()), id: \.element.id) { idx, s in
                    streakRow(s)
                    if idx < streak.streaks.count - 1 { RowDivider(inset: Theme.Spacing.lg) }
                }
            }
            .smokedGlass(radius: 24)
        }
        }
    }

    @ViewBuilder private var eventsSection: some View {
        if !visibleEvents.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                SectionHeader("Events")
                VStack(spacing: 0) {
                    ForEach(Array(visibleEvents.enumerated()), id: \.element.id) { idx, event in
                        eventRow(event)
                        if idx < visibleEvents.count - 1 { RowDivider(inset: Theme.Spacing.lg) }
                    }
                }
                .smokedGlass(radius: 24)
            }
        }
    }

    /// Only shown once there is history behind it — a brand-new user is never
    /// told they're missing something they never had.
    @ViewBuilder private var historyGate: some View {
        if hiddenHistoryCount > 0 {
            PremiumGateCard(
                title: "Your full history",
                message: "You're seeing the last 30 days. Premium opens \(hiddenHistoryCount) earlier \(hiddenHistoryCount == 1 ? "entry" : "entries") and the trends across all of it.")
        }
    }

    /// The calm home for slip-pattern insights. The Slip Log deliberately does
    /// not sell this at the moment someone logs a relapse; this is where the
    /// ask belongs.
    @ViewBuilder private var patternGate: some View {
        if !gems.isPremium, streak.slipPatternInsight() != nil {
            PremiumGateCard(
                title: "Slip-pattern insights",
                message: "There's a pattern in the slips you've logged — the time, the trigger, the feeling that keeps coming back. Premium names it.")
        }
    }

    private func eventRow(_ event: StreakEvent) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(event.type == .relapse ? "Slip" : event.type.rawValue.capitalized)
                    .font(Theme.Typography.cardTitle())
                    .foregroundStyle(Theme.Colors.textPrimary)
                if let detail = slipDetail(event) {
                    Text(detail)
                        .font(Theme.Typography.body())
                        .foregroundStyle(Theme.Colors.textSecondary)
                } else if let note = event.note, !note.isEmpty {
                    Text(note)
                        .font(Theme.Typography.body())
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            Spacer()
            // Forgiveness window: a slip logged today can be undone from here.
            if streak.isSlipUndoable(event) {
                Button {
                    Haptics.tap()
                    streak.undoSlip(event)
                } label: {
                    Text("Undo")
                        .font(Theme.Typography.bodyMedium())
                        .foregroundStyle(Theme.Colors.good)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, 8)
                        .background(Theme.Colors.good.opacity(0.14), in: Capsule())
                }
                .buttonStyle(PressableButtonStyle())
            } else {
                Text(RewireDate.full.string(from: event.date))
                    .font(Theme.Typography.body())
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
        }
        .padding(Theme.Spacing.md)
    }

    /// "Late night · Boredom · Anxious" — the pattern triad captured by the Slip Log.
    private func slipDetail(_ event: StreakEvent) -> String? {
        let parts = [event.timeOfDay, event.trigger, event.feeling].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private func streakRow(_ s: Streak) -> some View {
        Button { path.append(.streakDetail(s.index)) } label: {
            HStack(spacing: Theme.Spacing.md) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Streak #\(s.index)")
                        .font(Theme.Typography.cardTitle())
                        .foregroundStyle(Theme.Colors.textPrimary)
                    HStack(spacing: 6) {
                        Image(systemName: "clock").font(.system(size: 14))
                            .foregroundStyle(Theme.Colors.textSecondary)
                        // Ongoing streak IS the live one — its stored duration is a
                        // stale sample value; read the ticking timer instead.
                        Text((s.isOngoing ? streak.elapsed : s.duration).humanShort())
                            .font(Theme.Typography.body())
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
                Spacer()
                if s.isOngoing {
                    Text("ongoing").font(Theme.Typography.body()).foregroundStyle(Theme.Colors.good)
                }
                Image(systemName: "chevron.right").font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            .padding(Theme.Spacing.md)
        }
        .buttonStyle(.plain)
    }
}

/// Circular recovery progress ring with a leading dot cap.
struct RecoveryRing: View {
    let percent: Int
    /// Ring color — green for recovery, caller-supplied elsewhere (My Shield
    /// goes flame→gold→green as the level climbs).
    var tint: Color = Theme.Colors.good
    var body: some View {
        ZStack {
            Circle().stroke(Theme.Colors.surface2, lineWidth: 8)
            Circle()
                .trim(from: 0, to: max(0.01, CGFloat(percent) / 100))
                .stroke(tint, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(percent)%")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.Colors.textPrimary)
        }
    }
}

#Preview {
    ProgressTabView()
        .environment(AppState())
        .environment(GemStore())
        .environment(StreakStore())
}
