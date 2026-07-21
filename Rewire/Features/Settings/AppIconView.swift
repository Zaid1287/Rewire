import SwiftUI

/// App Icon picker (Settings → App Icon). Each tile renders the real icon
/// artwork — the brand 3-dot mark on the same ground as the shipped
/// .appiconset PNGs — so what you tap is what lands on the home screen.
struct AppIconView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedAppIcon") private var selected = 0

    /// Ground + mark colour per variant, mirroring the asset artwork.
    private struct IconStyle {
        let name: String
        let ground: AnyShapeStyle
        let dots: Color
    }

    private var styles: [IconStyle] {
        [
            IconStyle(name: "Void",
                      ground: AnyShapeStyle(Theme.Colors.background),
                      dots: Theme.Colors.butter),
            IconStyle(name: "Ember",
                      ground: AnyShapeStyle(LinearGradient(
                        colors: [Theme.Colors.emberHi, Theme.Colors.emberLo],
                        startPoint: .topLeading, endPoint: .bottomTrailing)),
                      dots: Theme.Colors.textHi),
            IconStyle(name: "Ivory",
                      ground: AnyShapeStyle(LinearGradient(
                        colors: [Theme.Colors.ivory, Color(hex: 0xC9C6C0)],
                        startPoint: .topLeading, endPoint: .bottomTrailing)),
                      dots: Theme.Colors.ink),
            IconStyle(name: "Cobalt",
                      ground: AnyShapeStyle(LinearGradient(
                        colors: [Color(hex: 0x4A63E8), Color(hex: 0x1D2FA8)],
                        startPoint: .topLeading, endPoint: .bottomTrailing)),
                      dots: Theme.Colors.textHi)
        ]
    }

    /// Alternate icon names — index 0 is the primary icon (nil).
    private let iconNames: [String?] = [nil, "AppIconFlame", "AppIconDrop", "AppIconBolt"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(title: "App Icon", showsBack: true, onBack: { dismiss() })
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(Array(styles.enumerated()), id: \.offset) { idx, style in
                        Button { Haptics.select(); select(idx) } label: {
                            VStack(spacing: 8) {
                                GeometryReader { geo in
                                    let side = geo.size.width
                                    RoundedRectangle(cornerRadius: side * 0.225, style: .continuous)
                                        .fill(style.ground)
                                        .overlay { BrandDots(size: side * 0.52, color: style.dots) }
                                        .overlay(
                                            RoundedRectangle(cornerRadius: side * 0.225, style: .continuous)
                                                .strokeBorder(selected == idx
                                                              ? Theme.Colors.butter
                                                              : Color.white.opacity(0.10),
                                                              lineWidth: selected == idx ? 2 : 1)
                                        )
                                }
                                .aspectRatio(1, contentMode: .fit)

                                Text(style.name)
                                    .font(Theme.Typography.caption())
                                    .foregroundStyle(selected == idx
                                                     ? Theme.Colors.textHi
                                                     : Theme.Colors.textXlo)
                            }
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
                .screenPadding()
                .padding(.top, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.tabBarClearance)
            }
        }
        .background { SceneBackground(kind: .void) }
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
