import SwiftUI

/// Edit start date (reached from the Home "Edit start" link). Replaces the old
/// whole-days-only "Add Days" stepper: the tracking reviews' loudest concrete
/// ask is an exact start — *"won't let me change my start day and time"*,
/// *"just a counter and being able to adjust it for a date in the past"* — and
/// a stepper that only shifts back in whole days can't set 9pm three days ago,
/// can't undo an over-add, and can't set the real start on first install.
///
/// RonLab Family A: Void scene, smoked glass, a Thin hero numeral previewing
/// the streak the picked instant produces so the consequence is visible before
/// committing. White capsule confirms.
struct EditStartView: View {
    @Environment(StreakStore.self) private var streak
    @Environment(\.dismiss) private var dismiss

    @State private var date: Date = Date()

    /// Seed with the current start so the picker opens where the streak is.
    init() {}

    private var elapsed: TimeInterval { max(0, Date().timeIntervalSince(date)) }
    /// Total whole days — same measure as the Home hero (`currentRunDays`),
    /// not the day-within-month that `StreakComponents` breaks out.
    private var previewDays: Int { Int(elapsed / 86_400) }
    private var remainder: StreakComponents { elapsed.streakComponents }

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(title: "Edit start", showsBack: true, onBack: { dismiss() })

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    // Live preview — the number is the point, so it's the hero.
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Streak becomes".uppercased())
                            .font(Theme.Typography.caption())
                            .tracking(1.4)
                            .foregroundStyle(Theme.Colors.textXlo)
                        HeroNumeral(value: "\(previewDays)",
                                    unit: previewDays == 1 ? "day" : "days",
                                    size: 76)
                        Text("\(remainder.hour)h \(remainder.minute)m and counting")
                            .font(Theme.Typography.label())
                            .foregroundStyle(Theme.Colors.textLo)
                            .monospacedDigit()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
                    .smokedGlass(radius: 32)

                    // Past-only: a future start would read as a negative streak.
                    DatePicker("Started",
                               selection: $date,
                               in: ...Date(),
                               displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.graphical)
                        .tint(Theme.Colors.butter)
                        .padding(Theme.Spacing.md)
                        .smokedGlass(radius: 32)

                    Text("Set this to when you actually last relapsed. Your best run is kept — this only moves the current streak.")
                        .font(Theme.Typography.caption())
                        .foregroundStyle(Theme.Colors.textXlo)
                        .fixedSize(horizontal: false, vertical: true)

                    PrimaryButton(title: "Set start") {
                        if streak.setStartDate(date) {
                            Haptics.success()
                            dismiss()
                        }
                    }
                }
                .screenPadding()
                .padding(.top, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.tabBarClearance)
            }
        }
        .background { SceneBackground(kind: .void) }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { date = streak.startDate }
    }
}
