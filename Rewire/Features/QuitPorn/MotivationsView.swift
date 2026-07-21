import SwiftUI

/// My Motivations sheet (Quit Porn → Willpower). Personal "why I quit" notes,
/// persisted via AppState, and re-surfaced in Panic Mode as a reminder.
struct MotivationsView: View {
    @Environment(AppState.self) private var appState
    @State private var text = ""

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            SheetChrome(title: "My Motivations")

            VStack(spacing: Theme.Spacing.sm) {
                TextField("Why are you quitting?", text: $text, axis: .vertical)
                    .font(Theme.Typography.body())
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.surface2, in: RoundedRectangle(cornerRadius: Theme.Radius.md))

                PrimaryButton(title: "Add") {
                    appState.addMotivation(text)
                    text = ""
                }
                .opacity(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .screenPadding()

            if appState.motivations.isEmpty {
                Spacer()
                Text("Write down why you're doing this — you'll see it when it matters most.")
                    .font(Theme.Typography.body())
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .screenPadding()
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(appState.motivations.enumerated()), id: \.element.id) { idx, m in
                            motivationRow(m)
                            if idx < appState.motivations.count - 1 { RowDivider(inset: Theme.Spacing.lg) }
                        }
                    }
                    .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
                    .screenPadding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background { SceneBackground(kind: .void) }
    }

    private func motivationRow(_ m: Motivation) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(m.text)
                    .font(Theme.Typography.body())
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text(RewireDate.full.string(from: m.date))
                    .font(Theme.Typography.caption())
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            Spacer()
            Button {
                Haptics.tap()
                appState.deleteMotivation(m)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
        }
        .padding(Theme.Spacing.md)
    }
}

#Preview { MotivationsView().environment(AppState()) }
