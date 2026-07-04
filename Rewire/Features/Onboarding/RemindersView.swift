import SwiftUI

/// Daily Reminders permission screen (IMG_5437): a mocked phone + watch
/// notification collage, "Daily Reminders" pitch, Enable + Do-it-later.
struct RemindersView: View {
    var onEnable: () -> Void
    var onLater: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            ReminderCollage()
                .frame(height: 360)
                .padding(.horizontal, Theme.Spacing.lg)

            VStack(spacing: Theme.Spacing.sm) {
                Text("Daily Reminders")
                    .font(Theme.Typography.title())
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text("Reminder notifications help make quitting your addiction way easier.")
                    .font(Theme.Typography.body())
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, Theme.Spacing.xl)
            .screenPadding()

            Spacer()

            VStack(spacing: Theme.Spacing.md) {
                PrimaryButton(title: "Enable Reminders", action: onEnable)
                HStack(spacing: 6) {
                    Image(systemName: "checkmark").foregroundStyle(Theme.Colors.textSecondary)
                    Text("We guarantee: Only helpful notifications.")
                        .font(Theme.Typography.subtitle())
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                Button("Do it later", action: onLater)
                    .font(Theme.Typography.body())
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .padding(.top, Theme.Spacing.xs)
            }
            .screenPadding()
            .padding(.bottom, Theme.Spacing.lg)
        }
        .background(Theme.Colors.background)
    }
}

/// Produced device mockups: phone lock-screen with a REWIRE check-in
/// notification, plus the watch daily check-in, overlapping bottom-right.
private struct ReminderCollage: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Image("reminders_phone")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 230)
                .frame(maxWidth: .infinity, alignment: .center)
            Image("reminders_watch")
                .resizable()
                .scaledToFit()
                .frame(width: 128)
                .offset(x: 6, y: -24)
                .shadow(color: .black.opacity(0.4), radius: 12, y: 6)
        }
    }
}

#Preview { RemindersView(onEnable: {}, onLater: {}) }
