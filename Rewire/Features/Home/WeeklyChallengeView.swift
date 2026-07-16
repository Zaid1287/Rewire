import SwiftUI

/// Weekly challenge (IMG_5457): "Week 27 of this year / 7-day event", a Join
/// Challenge CTA, and the 7 day rows with pending/failed markers.
struct WeeklyChallengeView: View {
    @Environment(StreakStore.self) private var streak
    @Environment(\.dismiss) private var dismiss

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
                    VStack(spacing: Theme.Spacing.xs) {
                        Text("Week 27 of this year")
                            .font(Theme.Typography.title())
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Text("7-day event")
                            .font(Theme.Typography.cardTitle())
                            .foregroundStyle(Theme.Colors.textSecondary)
                        Rectangle().fill(Theme.Colors.flame)
                            .frame(width: 140, height: 3)
                            .padding(.top, Theme.Spacing.xs)
                    }
                    .padding(.top, Theme.Spacing.lg)

                    Button {
                        guard !streak.challengeJoined else { return }
                        Haptics.success()
                        streak.joinChallenge()
                    } label: {
                        Text(streak.challengeJoined ? "Joined" : "Join Challenge")
                            .font(Theme.Typography.button())
                            .foregroundStyle(.white)
                            .padding(.horizontal, Theme.Spacing.xxl)
                            .frame(height: 56)
                            .background(Theme.Colors.primaryGradient, in: Capsule())
                            .opacity(streak.challengeJoined ? 0.5 : 1)
                    }
                    .buttonStyle(PressableButtonStyle())
                    .disabled(streak.challengeJoined)

                    VStack(spacing: Theme.Spacing.md) {
                        ForEach(streak.challengeDays) { day in
                            challengeRow(day)
                        }
                    }
                    .padding(.top, Theme.Spacing.sm)
                }
                .screenPadding()
                .padding(.bottom, Theme.Spacing.tabBarClearance)
            }
        }
        .background(Theme.Colors.background)
        // The screen draws its own back circle — hide the system one (on
        // iOS 26 it renders as a second glass circle right below ours).
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
    }

    private func challengeRow(_ day: ChallengeDay) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Text("\(day.number)")
                .font(Theme.Typography.headline())
                .foregroundStyle(Theme.Colors.textPrimary)
            Rectangle().fill(Theme.Colors.divider).frame(width: 1, height: 24)
            Text(day.dateLabel)
                .font(Theme.Typography.cardTitle())
                .foregroundStyle(Theme.Colors.textPrimary)
            Spacer()
            marker(for: day.state)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
        .contentShape(Rectangle())
        .onTapGesture {
            guard streak.challengeJoined else { return }
            Haptics.select()
            streak.setChallengeDay(day.number, to: day.state == .pending ? .done : .pending)
        }
    }

    @ViewBuilder
    private func marker(for state: ChallengeDay.State) -> some View {
        switch state {
        case .pending:
            Circle().strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                .foregroundStyle(Theme.Colors.textTertiary)
                .frame(width: 24, height: 24)
        case .done:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.white, Theme.Colors.green).font(.system(size: 24))
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.white, Theme.Colors.flame).font(.system(size: 24))
        }
    }
}

#Preview { WeeklyChallengeView().environment(StreakStore()) }
