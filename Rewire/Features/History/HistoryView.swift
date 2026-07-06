import SwiftUI

/// History tab (IMG_5466): a Statistics entry, the list of streaks, and a
/// floating "Add Event" button.
struct HistoryView: View {
    @Environment(StreakStore.self) private var streak
    enum Route: Hashable { case statistics, streakDetail(Int) }
    @State private var path: [Route] = []
    @State private var showAddEvent = false
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                NavHeader(title: "History") {
                    Button { Haptics.tap(); showDeleteAlert = true } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .frame(width: 40, height: 40)
                            .overlay(Circle().stroke(Theme.Colors.divider, lineWidth: 1))
                    }
                }

                ZStack(alignment: .bottomTrailing) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                            Button { path.append(.statistics) } label: {
                                FeatureRow(item: FeatureItem(
                                    symbol: "chart.bar.xaxis", title: "Statistics",
                                    subtitle: "Track your progress with detailed statistics."))
                                .padding(.horizontal, Theme.Spacing.md)
                                .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
                            }
                            .buttonStyle(PressableButtonStyle())

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
                        .screenPadding()
                        .padding(.top, Theme.Spacing.lg)
                        .padding(.bottom, 140)
                    }

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
            }
            .background(Theme.Colors.background)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .statistics: StatisticsView()
                case .streakDetail(let i): StreakDetailView(index: i)
                }
            }
            .sheet(isPresented: $showAddEvent) {
                AddEventView().presentationDetents([.medium])
            }
            .overlay {
                if showDeleteAlert {
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
        }
        .tint(Theme.Colors.green)
    }

    private func eventRow(_ event: StreakEvent) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(event.type.rawValue.capitalized)
                    .font(Theme.Typography.cardTitle())
                    .foregroundStyle(Theme.Colors.textPrimary)
                if let note = event.note, !note.isEmpty {
                    Text(note)
                        .font(Theme.Typography.body())
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            Spacer()
            Text(RewireDate.full.string(from: event.date))
                .font(Theme.Typography.body())
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .padding(Theme.Spacing.md)
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
                        Text(s.duration.humanShort())
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

#Preview { HistoryView().environment(StreakStore()) }
