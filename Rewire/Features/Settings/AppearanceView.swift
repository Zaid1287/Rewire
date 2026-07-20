import SwiftUI

/// Appearance (Settings → Appearance). Dark / Light / System theme picker,
/// persisted on AppState and applied app-wide via preferredColorScheme.
struct AppearanceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    private let options: [AppState.Appearance] = [.dark, .light, .system]

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(title: "Appearance", showsBack: true, onBack: { dismiss() })
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    SectionHeader("Theme")
                    VStack(spacing: 0) {
                        ForEach(Array(options.enumerated()), id: \.offset) { idx, option in
                            Button {
                                Haptics.select()
                                withAnimation(Theme.Motion.standard) { appState.setAppearance(option) }
                            } label: {
                                HStack {
                                    Text(option.title)
                                        .font(Theme.Typography.cardTitle())
                                        .foregroundStyle(Theme.Colors.textPrimary)
                                    Spacer()
                                    if appState.appearance == option {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.white, Theme.Colors.green)
                                    }
                                }
                                .padding(Theme.Spacing.md)
                            }
                            .buttonStyle(.plain)
                            if idx < options.count - 1 { RowDivider() }
                        }
                    }
                    .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
                }
                .screenPadding()
                .padding(.top, Theme.Spacing.md)
            }
        }
        .background(Theme.Colors.background)
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview { NavigationStack { AppearanceView() }.environment(AppState()) }
