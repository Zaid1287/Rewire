import SwiftUI

/// Add Days (reached from the Home "ADD DAYS →" link). Not shown as a distinct
/// screenshot, so this is a faithful, minimal editor consistent with the app's
/// grouped-list style: pick how many days to add to the current streak.
struct AddDaysView: View {
    @Environment(StreakStore.self) private var streak
    @Environment(\.dismiss) private var dismiss
    @State private var days = 1

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(title: "Add Days", showsBack: true, onBack: { dismiss() })

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    HStack(alignment: .top, spacing: Theme.Spacing.md) {
                        Image(systemName: "info.circle").font(.system(size: 22))
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Text("Forgot to track earlier days? Add them to your current streak.")
                            .font(Theme.Typography.cardTitle())
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, Theme.Spacing.md)

                    Card {
                        HStack {
                            Text("Days to add")
                                .font(Theme.Typography.cardTitle())
                                .foregroundStyle(Theme.Colors.textPrimary)
                            Spacer()
                            Stepper(value: $days, in: 1...365) {
                                Text("\(days)")
                                    .font(Theme.Typography.statNumber())
                                    .foregroundStyle(Theme.Colors.textPrimary)
                                    .frame(minWidth: 44)
                            }
                            .labelsHidden()
                        }
                    }

                    PrimaryButton(title: "Add \(days) day\(days == 1 ? "" : "s")") {
                        // Shift the streak start earlier by the chosen days.
                        streak.addDays(days)
                        dismiss()
                    }
                }
                .screenPadding()
                .padding(.bottom, 120)
            }
        }
        .background(Theme.Colors.background)
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
    }
}
