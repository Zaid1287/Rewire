import SwiftUI

/// Progress tab (flow-redesign Phase 4, plan §1): Recovery + History merged —
/// "how am I doing?" is one mental model. Recovery ring, badges/levels
/// collection, superpowers preview, statistics, streak history, and events
/// (with slip undo), plus the floating Add Event button.
/// Named ProgressTabView because SwiftUI owns `ProgressView`.
struct ProgressTabView: View {
    enum Route: Hashable { case superpowers, badges, levels, statistics, streakDetail(Int) }
    @Environment(AppState.self) private var appState
    @Environment(GemStore.self) private var gems
    @Environment(StreakStore.self) private var streak
    @State private var path: [Route] = []
    @State private var showAddEvent = false
    @State private var showDeleteAlert = false

    /// Recovery % — current streak against the standard 90-day rewire window.
    private var recoveryPercent: Int {
        min(100, Int(streak.elapsed / 86_400 / 90 * 100))
    }

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
                            collection
                            superpowersPreview
                            statisticsRow
                            streaksSection
                            eventsSection
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
                        .foregroundStyle(.white)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .frame(height: 54)
                        .background(Theme.Colors.primaryGradient, in: Capsule())
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
            .background(Theme.Colors.background)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .superpowers: SuperpowersView()
                case .badges:      BadgesView()
                case .levels:      LevelsView()
                case .statistics:  StatisticsView()
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
        .tint(Theme.Colors.green)
    }

    // MARK: Recovery sections (from the old Recovery tab)

    private var recoveryHeader: some View {
        HStack(spacing: Theme.Spacing.lg) {
            RecoveryRing(percent: recoveryPercent)
                .frame(width: 92, height: 92)
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack(spacing: Theme.Spacing.xs) {
                    Text("Your recovery")
                        .font(Theme.Typography.cardTitle())
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Image(systemName: "info.circle")
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                Text("Keep your streak to recover completely.")
                    .font(Theme.Typography.body())
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    private var collection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader("My Collection")
            HStack(spacing: Theme.Spacing.md) {
                collectionCard(icon: "rosette", iconColor: Theme.Colors.purple,
                               title: "Badges",
                               badge: unclaimedBadges == 0 ? nil : unclaimedBadges,
                               value: "\(gems.claimedBadges.count)", unit: "badges") {
                    path.append(.badges)
                }
                collectionCard(icon: "trophy.fill", iconColor: Theme.Colors.gold,
                               title: "Levels",
                               badge: nil,
                               value: SampleData.levels.first(where: { $0.rank == gems.currentLevel })?.name ?? "Newcomer",
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
            .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var superpowersPreview: some View {
        VStack(spacing: Theme.Spacing.md) {
            SectionHeader(title: "Superpowers") {
                LinkButton(title: "Show All") { path.append(.superpowers) }
            }
            Card(padding: Theme.Spacing.md) {
                VStack(spacing: 0) {
                    BenefitRow(benefit: SampleData.benefits[0], showProgress: true, progress: 0.08)
                    RowDivider()
                    BenefitRow(benefit: SampleData.benefits[1], showProgress: true, progress: 0.08)
                }
            }
        }
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
            .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
        }
    }

    // MARK: History sections (from the old History tab)

    private var statisticsRow: some View {
        Button { path.append(.statistics) } label: {
            FeatureRow(item: FeatureItem(
                symbol: "chart.bar.xaxis", title: "Statistics",
                subtitle: "Track your progress with detailed statistics."))
            .padding(.horizontal, Theme.Spacing.md)
            .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var streaksSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader("My Streaks")
            VStack(spacing: 0) {
                ForEach(Array(streak.streaks.enumerated()), id: \.element.id) { idx, s in
                    streakRow(s)
                    if idx < streak.streaks.count - 1 { RowDivider(inset: Theme.Spacing.lg) }
                }
            }
            .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
        }
    }

    @ViewBuilder private var eventsSection: some View {
        if !streak.events.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                SectionHeader("Events")
                VStack(spacing: 0) {
                    ForEach(Array(streak.events.enumerated()), id: \.element.id) { idx, event in
                        eventRow(event)
                        if idx < streak.events.count - 1 { RowDivider(inset: Theme.Spacing.lg) }
                    }
                }
                .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
            }
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
                        .foregroundStyle(Theme.Colors.green)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, 8)
                        .background(Theme.Colors.green.opacity(0.14), in: Capsule())
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
                    Text("ongoing").font(Theme.Typography.body()).foregroundStyle(Theme.Colors.green)
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
    var tint: Color = Theme.Colors.green
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
