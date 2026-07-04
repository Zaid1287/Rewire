import SwiftUI

/// Add Event sheet (History → Add Event). No dedicated screenshot; a faithful
/// minimal editor matching the app's option-list style: pick an event type.
struct AddEventView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selected: String? = nil

    private let events = ["Relapse", "Wet dream", "Edging", "Watched porn", "Masturbated"]

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Capsule().fill(Theme.Colors.textTertiary).frame(width: 40, height: 5)
                .padding(.top, Theme.Spacing.sm)
            Text("Add Event")
                .font(Theme.Typography.cardTitle())
                .foregroundStyle(Theme.Colors.textPrimary)

            VStack(spacing: Theme.Spacing.sm) {
                ForEach(events, id: \.self) { event in
                    RadioOptionRow(text: event, isSelected: selected == event) { selected = event }
                }
            }
            .screenPadding()

            PrimaryButton(title: "Save Event") { dismiss() }
                .screenPadding()
                .opacity(selected == nil ? 0.5 : 1)
                .disabled(selected == nil)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.Colors.background)
    }
}

#Preview { AddEventView() }
