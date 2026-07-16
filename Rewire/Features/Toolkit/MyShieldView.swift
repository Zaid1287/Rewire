import SwiftUI

/// My Shield (Toolkit → "Power up your shield"): a checklist of real actions
/// that harden a streak, with a shield level derived from how many are done.
/// Recreates the reference app's screen, adapted to Rewire's honest state:
/// every checkmark is wired to real data (no free-claiming), dead features
/// (relapse penalty) are replaced, and unshipped ones stay dimmed "Soon".
struct MyShieldView: View {
    @Environment(AppState.self) private var appState
    @Environment(GemStore.self) private var gems
    @Environment(StreakStore.self) private var streak
    @Environment(\.dismiss) private var dismiss

    @State private var showReminders = false
    @State private var showMotivations = false
    @State private var showBreathing = false
    @State private var showCheckIn = false

    /// One checklist row: completion is always derived, never toggled by hand.
    private struct Task: Identifiable {
        let id: String
        let symbol: String
        let title: String
        let subtitle: String
        let done: Bool
        var soon: Bool = false
        var action: (() -> Void)? = nil
    }

    private var tasks: [Task] {
        [
            Task(id: "firstMinute", symbol: "1.circle",
                 title: "Complete your first 1 minute",
                 subtitle: "Enjoy your first victory against porn addiction.",
                 done: streak.elapsed >= 60 || streak.totalCleanDays > 0),
            Task(id: "blocker", symbol: "checkmark.shield",
                 title: "Enable your porn blocker",
                 subtitle: "Block porn websites. Avoid unexpected relapses.",
                 done: false, soon: true),
            Task(id: "reminders", symbol: "app.badge",
                 title: "Enable reminder notifications",
                 subtitle: "You will get only useful notifications. We promise!",
                 done: appState.reminderEnabled,
                 action: { showReminders = true }),
            Task(id: "plan", symbol: "21.circle",
                 title: "Start your personal plan",
                 subtitle: "Complete the first step of your personal plan.",
                 done: !streak.completedPlanDays.isEmpty),
            Task(id: "community", symbol: "person.2",
                 title: "Join our private community",
                 subtitle: "Join the private Telegram group. Get amazing support.",
                 done: false, soon: true),
            Task(id: "widgets", symbol: "square.on.square.dashed",
                 title: "Add home screen widgets",
                 subtitle: "Rewire widgets will keep you on your toes.",
                 done: false, soon: true),
            Task(id: "motivations", symbol: "bolt",
                 title: "Add your motivations",
                 subtitle: "Never forget why you want to quit your addiction.",
                 done: !appState.motivations.isEmpty,
                 action: { showMotivations = true }),
            Task(id: "breathing", symbol: "lungs",
                 title: "Do daily breathing exercises",
                 subtitle: "Stay calm with breathing exercises and avoid relapses.",
                 done: gems.achievements.contains("breathing"),
                 action: { showBreathing = true }),
            Task(id: "challenge", symbol: "rosette",
                 title: "Accept the challenges",
                 subtitle: "Join weekly challenges. Track your success.",
                 done: streak.challengeJoined),
            Task(id: "checkin", symbol: "square.and.pencil",
                 title: "Complete your daily check-in",
                 subtitle: "Three seconds. That's the whole ritual.",
                 done: !streak.reports.isEmpty,
                 action: { showCheckIn = true }),
            // Replaces the reference app's "relapse penalty" row — Rewire
            // doesn't punish slips; logging them honestly IS the power-up.
            Task(id: "pattern", symbol: "sparkles",
                 title: "Log slips honestly",
                 subtitle: "Every logged slip builds your pattern insight. No penalties.",
                 done: streak.events.contains { $0.type == .relapse }),
            Task(id: "firstDay", symbol: "sunrise",
                 title: "Complete your first day",
                 subtitle: "You will remember today when you quit completely.",
                 done: streak.currentRunDays >= 1 || streak.totalCleanDays >= 1)
        ]
    }

    private var shieldPercent: Int {
        let done = tasks.filter(\.done).count
        return Int((Double(done) / Double(tasks.count) * 100).rounded())
    }

    private var ringTint: Color {
        switch shieldPercent {
        case ..<34:  Theme.Colors.flame
        case ..<67:  Theme.Colors.star
        default:     Theme.Colors.green
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(title: "My Shield", showsBack: true, onBack: { dismiss() })

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    header

                    if shieldPercent < 50 {
                        HStack(spacing: Theme.Spacing.xs) {
                            Text("❗️")
                            Text("\(shieldPercent)% is not enough to avoid relapses.")
                                .font(Theme.Typography.bodyMedium())
                                .foregroundStyle(Theme.Colors.flame)
                        }
                    }

                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        SectionHeader("Power up your shield")
                        VStack(spacing: 0) {
                            ForEach(Array(tasks.enumerated()), id: \.element.id) { idx, task in
                                taskRow(task)
                                if idx < tasks.count - 1 { RowDivider(inset: 92) }
                            }
                        }
                        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
                    }
                }
                .screenPadding()
                .padding(.top, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.tabBarClearance)
            }
            .collapsesDock()
        }
        .background(Theme.Colors.background)
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showReminders) {
            ReminderSettingsView().presentationDetents([.medium])
        }
        .sheet(isPresented: $showMotivations) {
            MotivationsView().presentationDetents([.large])
        }
        .sheet(isPresented: $showBreathing) {
            PanicModeView()
                .background(Theme.Colors.background)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showCheckIn) {
            CheckInFlow().presentationDetents([.medium])
        }
    }

    private var header: some View {
        HStack(spacing: Theme.Spacing.lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "shield.lefthalf.filled")
                        .foregroundStyle(Theme.Colors.green)
                    Text("Your shield level")
                        .font(Theme.Typography.cardTitle())
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
                Text("Increase your shield level to keep your streak easily.")
                    .font(Theme.Typography.body())
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            RecoveryRing(percent: shieldPercent, tint: ringTint)
                .frame(width: 84, height: 84)
        }
    }

    @ViewBuilder private func taskRow(_ task: Task) -> some View {
        let content = HStack(spacing: Theme.Spacing.md) {
            // Derived checkbox — a green check when the underlying state is
            // real, a dashed empty circle until then.
            if task.done {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white, Theme.Colors.green)
            } else {
                Circle()
                    .strokeBorder(Theme.Colors.textTertiary,
                                  style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                    .frame(width: 24, height: 24)
            }

            Image(systemName: task.symbol)
                .font(.system(size: 20))
                .foregroundStyle(Theme.Colors.textPrimary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Theme.Spacing.xs) {
                    Text(task.title)
                        .font(Theme.Typography.headline())
                        .foregroundStyle(Theme.Colors.textPrimary)
                    if task.soon {
                        Text("Soon")
                            .font(Theme.Typography.caption())
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .padding(.horizontal, Theme.Spacing.xs)
                            .padding(.vertical, 2)
                            .background(Theme.Colors.surface2, in: Capsule())
                    }
                }
                Text(task.subtitle)
                    .font(Theme.Typography.subtitle())
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            if task.action != nil && !task.done {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
        }
        .padding(Theme.Spacing.md)
        .opacity(task.soon ? 0.45 : 1)

        if let action = task.action, !task.done, !task.soon {
            Button(action: { Haptics.tap(); action() }) { content }
                .buttonStyle(.plain)
        } else {
            content
        }
    }
}

#Preview {
    NavigationStack { MyShieldView() }
        .environment(AppState())
        .environment(GemStore())
        .environment(StreakStore())
}
