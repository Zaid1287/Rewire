import SwiftUI

/// App Icon picker (Settings → App Icon). No dedicated screenshot; a faithful
/// minimal grid of alternate marks built from the design system.
struct AppIconView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedAppIcon") private var selected = 0

    private let icons: [(String, Color, Color)] = [
        ("checkmark.shield.fill", Theme.Colors.greenDark, Theme.Colors.pastelLime),
        ("flame.fill", .white, Theme.Colors.flame),
        ("drop.fill", .white, Theme.Colors.primary),
        ("bolt.fill", .black, Theme.Colors.noteYellow)
    ]
    /// Alternate icon names — index 0 is the primary icon (nil). The bundle
    /// ships no alternate .appiconset yet, so the system call fails gracefully
    /// and only the in-app selection updates until the assets land.
    private let iconNames: [String?] = [nil, "AppIconFlame", "AppIconDrop", "AppIconBolt"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: Theme.Spacing.md), count: 3)

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(title: "App Icon", showsBack: true, onBack: { dismiss() })
            ScrollView {
                LazyVGrid(columns: columns, spacing: Theme.Spacing.lg) {
                    ForEach(Array(icons.enumerated()), id: \.offset) { idx, icon in
                        Button { Haptics.select(); select(idx) } label: {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(icon.2)
                                .aspectRatio(1, contentMode: .fit)
                                .overlay(Image(systemName: icon.0)
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundStyle(icon.1))
                                .overlay(RoundedRectangle(cornerRadius: 20)
                                    .stroke(Theme.Colors.green, lineWidth: selected == idx ? 3 : 0))
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
                .screenPadding()
                .padding(.top, Theme.Spacing.lg)
            }
        }
        .background(Theme.Colors.background)
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
    }

    private func select(_ idx: Int) {
        selected = idx
        UIApplication.shared.setAlternateIconName(iconNames[idx]) { error in
            if let error { print("App icon change failed: \(error.localizedDescription)") }
        }
    }
}

#Preview { NavigationStack { AppIconView() } }
