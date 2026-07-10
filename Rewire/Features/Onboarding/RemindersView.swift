import SwiftUI

/// Daily Reminders onboarding step: a lock-screen-style notification preview
/// that live-updates as the user picks their reminder time, then Enable
/// schedules at exactly that time. Replaces the old static phone/watch
/// mockup collage.
struct RemindersView: View {
    var onEnable: (_ hour: Int, _ minute: Int) -> Void
    var onLater: () -> Void

    /// Defaults to 9:00 PM — the evening hours are when reminders matter most.
    @State private var time = Calendar.current.date(
        bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date()

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            notificationPreview
                .screenPadding()

            VStack(spacing: Theme.Spacing.sm) {
                Text("Daily Reminders")
                    .font(Theme.Typography.title())
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text("One helpful nudge a day, at a time you choose.")
                    .font(Theme.Typography.body())
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, Theme.Spacing.xl)
            .screenPadding()

            DatePicker("Reminder time", selection: $time, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(height: 140)
                .clipped()
                .padding(.top, Theme.Spacing.sm)

            Spacer()

            VStack(spacing: Theme.Spacing.md) {
                PrimaryButton(title: "Enable Reminders") {
                    let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
                    onEnable(comps.hour ?? 21, comps.minute ?? 0)
                }
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            ZStack {
                Theme.Colors.background
                // Soft indigo glow behind the notification card.
                RadialGradient(colors: [Theme.Colors.primary.opacity(0.22), .clear],
                               center: UnitPoint(x: 0.5, y: 0.28),
                               startRadius: 20, endRadius: 320)
            }
            .ignoresSafeArea()
        }
    }

    /// Drawn lock-screen banner — what the daily reminder will actually look
    /// like, stamped with the picked time.
    private var notificationPreview: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            AppLogoSmall()
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("REWIRE")
                        .font(Theme.Typography.caption().weight(.semibold))
                        .tracking(0.8)
                        .foregroundStyle(Theme.Colors.textSecondary)
                    Spacer()
                    Text(time.formatted(date: .omitted, time: .shortened))
                        .font(Theme.Typography.caption())
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .contentTransition(.numericText())
                        .animation(Theme.Motion.standard, value: time)
                }
                Text("Time to check in 💪")
                    .font(Theme.Typography.bodyMedium())
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text("Stay on your streak — log today and keep your momentum going.")
                    .font(Theme.Typography.subtitle())
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .fill(Theme.Colors.surface2.opacity(0.92))
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .stroke(Theme.Colors.divider, lineWidth: 1))
        )
        .themeShadow(Theme.Shadows.floating)
    }
}

#Preview { RemindersView(onEnable: { _, _ in }, onLater: {}) }
