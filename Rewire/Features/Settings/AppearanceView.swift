import SwiftUI

/// Appearance (Settings → Appearance). No dedicated screenshot; a faithful
/// minimal theme picker. The app is dark-only, so light/system are shown as
/// coming-soon to stay honest about current support.
struct AppearanceView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selection = "Dark"
    private let options = ["Dark", "Light", "System"]

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(title: "Appearance", showsBack: true, onBack: { dismiss() })
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    SectionHeader("Theme")
                    VStack(spacing: 0) {
                        ForEach(Array(options.enumerated()), id: \.offset) { idx, option in
                            Button { if option == "Dark" { selection = option } } label: {
                                HStack {
                                    Text(option)
                                        .font(Theme.Typography.cardTitle())
                                        .foregroundStyle(option == "Dark" ? Theme.Colors.textPrimary : Theme.Colors.textTertiary)
                                    if option != "Dark" {
                                        Text("Soon").font(Theme.Typography.caption())
                                            .foregroundStyle(Theme.Colors.textTertiary)
                                            .padding(.horizontal, 8).padding(.vertical, 2)
                                            .background(Theme.Colors.surface2, in: Capsule())
                                    }
                                    Spacer()
                                    if selection == option {
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

#Preview { NavigationStack { AppearanceView() } }
