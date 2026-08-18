import SwiftUI

/// Weekly challenge: stay clean for the seven days of *this* week.
///
/// Every day here is answered by the streak record — a slip logged on a day
/// marks it failed, a finished day without one marks it clean — using the same
/// rule as the Home strip and the widget. Nothing is tappable: the previous
/// version let you mark any day done by hand, which made a perfect week worth
/// exactly as much as tapping seven rows, and shipped a hardcoded failure on
/// day 6 so a brand-new user opened it to a red X.
///
/// Joining is per week, so it's a commitment you renew rather than a box you
/// ticked once. Reviewers ask for this feature by name — see the Paywall /
/// Challenges evidence in CLUSTER-SOLUTIONS.md — so it earns its place, but
/// only if it reflects what actually happened.
struct WeeklyChallengeView: View {
    @Environment(StreakStore.self) private var streak
    @Environment(\.dismiss) private var dismiss

    private var days: [ChallengeDay] { streak.challengeDays }

    private var weekNumber: Int {
        Calendar.current.component(.weekOfYear, from: Date())
    }

    private var dateRange: String {
        guard let first = days.first?.date, let last = days.last?.date else { return "" }
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return "\(f.string(from: first)) – \(f.string(from: last))"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                CircleBackButton { dismiss() }
                Spacer()
            }
            .screenPadding()
            .padding(.top, Theme.Spacing.xs)

            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    header
                    joinButton
                    progressLine

                    VStack(spacing: Theme.Spacing.md) {
                        ForEach(days) { day in
                            challengeRow(day)
                        }
                    }
                    .padding(.top, Theme.Spacing.sm)

                    Text("Days are filled in from your own record — a slip you log marks its day, nothing here is tapped in by hand.")
                        .font(Theme.Typography.caption())
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, Theme.Spacing.xs)
                }
                .screenPadding()
                .padding(.bottom, Theme.Spacing.tabBarClearance)
            }
        }
        .background { SceneBackground(kind: .void) }
        // The screen draws its own back circle — hide the system one (on
        // iOS 26 it renders as a second glass circle right below ours).
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text("Week \(weekNumber)")
                .font(Theme.Typography.title())
                .foregroundStyle(Theme.Colors.textPrimary)
            Text(dateRange)
                .font(Theme.Typography.cardTitle())
                .foregroundStyle(Theme.Colors.textSecondary)
            Rectangle().fill(Theme.Colors.butter)
                .frame(width: 140, height: 3)
                .padding(.top, Theme.Spacing.xs)
        }
        .padding(.top, Theme.Spacing.lg)
    }

    private var joinButton: some View {
        Button {
            guard !streak.challengeJoined else { return }
            Haptics.success()
            streak.joinChallenge()
        } label: {
            Text(streak.challengeJoined ? "You're in this week" : "Join this week")
                .font(Theme.Typography.button())
                .foregroundStyle(.white)
                .padding(.horizontal, Theme.Spacing.xxl)
                .frame(height: 56)
                .background(Theme.Colors.primaryGradient, in: Capsule())
                .opacity(streak.challengeJoined ? 0.5 : 1)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(streak.challengeJoined)
    }

    /// Finished days only, so the first day of the week reads "the week starts
    /// today" rather than "0 of 7" — this isn't a deficit you begin behind on.
    private var progressLine: some View {
        let p = streak.challengeProgress
        return Text(p.finished == 0
                    ? "The week starts today."
                    : "\(p.clean) of \(p.finished) day\(p.finished == 1 ? "" : "s") clean so far.")
            .font(Theme.Typography.subtitle())
            .foregroundStyle(Theme.Colors.textSecondary)
    }

    private func challengeRow(_ day: ChallengeDay) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Text("\(day.number)")
                .font(Theme.Typography.headline())
                .foregroundStyle(day.state == .upcoming
                                 ? Theme.Colors.textTertiary : Theme.Colors.textPrimary)
            Rectangle().fill(Theme.Colors.divider).frame(width: 1, height: 24)
            Text(day.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                .font(Theme.Typography.cardTitle())
                .foregroundStyle(day.state == .upcoming
                                 ? Theme.Colors.textTertiary : Theme.Colors.textPrimary)
            Spacer()
            marker(for: day.state)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
        .overlay {
            if day.state == .today {
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .strokeBorder(Theme.Colors.butter.opacity(0.6), lineWidth: 1)
            }
        }
    }

    @ViewBuilder
    private func marker(for state: ChallengeDay.State) -> some View {
        switch state {
        case .upcoming:
            Circle().strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                .foregroundStyle(Theme.Colors.textTertiary)
                .frame(width: 24, height: 24)
        case .today:
            Text("Today")
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Colors.butter)
        case .done:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.white, Theme.Colors.good).font(.system(size: 24))
        case .failed:
            // Grey, never red — red means relapse-day panic elsewhere in the
            // app, and a logged slip is honesty, not an alarm.
            Image(systemName: "minus.circle.fill")
                .foregroundStyle(.white, Theme.Colors.textTertiary).font(.system(size: 24))
        }
    }
}

#Preview { WeeklyChallengeView().environment(StreakStore()) }
