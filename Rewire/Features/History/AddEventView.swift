import SwiftUI

/// Add Event sheet (History → Add Event). No dedicated screenshot; a faithful
/// minimal editor matching the app's option-list style: pick an event type.
struct AddEventView: View {
    @Environment(StreakStore.self) private var streak
    @Environment(\.dismiss) private var dismiss
    @State private var selected: String? = nil

    private let events = ["Relapse", "Wet dream", "Edging", "Watched porn", "Masturbated"]

    /// Maps this screen's options onto the shared StreakEvent.Kind — only
    /// "Relapse" is a true relapse; the rest are logged as notes.
    private func kind(for event: String) -> StreakEvent.Kind {
        event == "Relapse" ? .relapse : .note
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            SheetChrome(title: "Add Event", titleFont: Theme.Typography.cardTitle())

            VStack(spacing: Theme.Spacing.sm) {
                ForEach(events, id: \.self) { event in
                    RadioOptionRow(text: event, isSelected: selected == event) { selected = event }
                }
            }
            .screenPadding()

            PrimaryButton(title: "Save Event") {
                guard let selected else { return }
                // Relapse titles itself via its kind; only note-kinds carry the label.
                streak.addEvent(StreakEvent(type: kind(for: selected),
                                            note: selected == "Relapse" ? nil : selected))
                Haptics.success()
                dismiss()
            }
                .screenPadding()
                .opacity(selected == nil ? 0.5 : 1)
                .disabled(selected == nil)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background { SceneBackground(kind: .void) }
    }
}

#Preview { AddEventView().environment(StreakStore()) }
