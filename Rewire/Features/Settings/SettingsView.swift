import SwiftUI

/// Settings tab — RonLab Family B (Slate): grouped opaque cards with hairline
/// row dividers, monochrome icon squircles, app-icon picker, and the
/// butter-gradient premium card. This is the expected, low-risk paywall entry.
/// The Appearance picker is retired: scenes are fixed per screen, so a
/// light/dark toggle has nothing left to switch.
struct SettingsView: View {
    @Environment(GemStore.self) private var gems
    @Environment(\.openURL) private var openURL
    /// The four bundled icons — index 0 is the primary (nil alternate name).
    @AppStorage("selectedAppIcon") private var selectedIcon = 0
    @State private var showPaywall = false
    @State private var showRestoredAlert = false
    // Moved here from the old Quit Porn hub (Phase 4) — they're settings.
    @State private var showReminders = false
    @State private var showFaceIDSettings = false
    @State private var showDataBackup = false

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SceneBackground(kind: .slate)
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("No account — everything stays on this phone.")
                            .font(Theme.Typography.caption())
                            .foregroundStyle(Theme.Colors.textXlo)
                            .padding(.horizontal, 6)

                        appIconSection

                        section("General") {
                            slateRow("bell", "Daily Reminders",
                                     accessory: .chevron) { showReminders = true }
                            divider
                            slateRow("faceid", "App Lock · Face ID",
                                     accessory: .chevron) { showFaceIDSettings = true }
                        }

                        section("Privacy & data") {
                            slateRow("shield", "Privacy Policy",
                                     accessory: .chevron) { openURL(Legal.privacyURL) }
                            divider
                            slateRow("doc.text", "Terms of Service",
                                     accessory: .chevron) { openURL(Legal.termsURL) }
                            divider
                            slateRow("arrow.down.circle", "Export Data",
                                     accessory: .value("JSON")) { showDataBackup = true }
                            divider
                            slateRow("arrow.clockwise", "Restore Purchase",
                                     accessory: .chevron) { restorePurchase() }
                        }

                        section("Support") {
                            slateRow("paperplane", "Give Feedback",
                                     accessory: .chevron, enabled: false) {}
                            divider
                            inviteRow
                        }

                        // Lifetime owners have nothing left to buy.
                        if gems.canUpgrade { premiumCard }

                        Text("Rewire v\(appVersion)")
                            .font(Theme.Typography.caption())
                            .foregroundStyle(Theme.Colors.textXlo)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 6)
                    }
                    .screenPadding()
                    .padding(.top, Theme.Spacing.md)
                    .padding(.bottom, Theme.Spacing.tabBarClearance)
                }
                .collapsesDock()
            }
            // Floating glass header — content scrolls underneath.
            .safeAreaInset(edge: .top) {
                NavHeader(title: "Settings") { CoinPill(count: gems.coins) }
                    .background { TopFadeScrim() }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showPaywall) {
                PaywallSheet().presentationDetents([.large])
            }
            .sheet(isPresented: $showReminders) {
                ReminderSettingsView().presentationDetents([.medium])
            }
            .sheet(isPresented: $showFaceIDSettings) {
                FaceIDSettingsView().presentationDetents([.medium])
            }
            .sheet(isPresented: $showDataBackup) {
                DataBackupView().presentationDetents([.medium])
            }
            .rewireAlert(isPresented: showRestoredAlert) {
                RewireAlert(
                    title: "Purchases Restored",
                    message: "Your premium access has been restored.",
                    confirmTitle: "OK",
                    confirmIsDestructive: false,
                    onCancel: { showRestoredAlert = false },
                    onConfirm: { showRestoredAlert = false }
                )
            }
        }
        .tint(Theme.Colors.butter)
    }

    private func restorePurchase() {
        gems.unlockPremium(plan: "1 year")   // mock restore — real plan comes with StoreKit
        Haptics.success()
        showRestoredAlert = true
    }

    // MARK: App icon picker

    /// Ground + mark colour per variant, mirroring the shipped .appiconset art.
    private struct IconOption {
        let name: String
        let alternate: String?          // nil = primary icon
        let ground: AnyShapeStyle
        let dots: Color
    }

    private var iconOptions: [IconOption] {
        [
            IconOption(name: "Void", alternate: nil,
                       ground: AnyShapeStyle(Theme.Colors.background),
                       dots: Theme.Colors.butter),
            IconOption(name: "Ember", alternate: "AppIconFlame",
                       ground: AnyShapeStyle(LinearGradient(
                        colors: [Theme.Colors.emberHi, Theme.Colors.emberLo],
                        startPoint: .topLeading, endPoint: .bottomTrailing)),
                       dots: Theme.Colors.textHi),
            IconOption(name: "Ivory", alternate: "AppIconDrop",
                       ground: AnyShapeStyle(LinearGradient(
                        colors: [Theme.Colors.ivory, Color(hex: 0xC9C6C0)],
                        startPoint: .topLeading, endPoint: .bottomTrailing)),
                       dots: Theme.Colors.ink),
            IconOption(name: "Cobalt", alternate: "AppIconBolt",
                       ground: AnyShapeStyle(LinearGradient(
                        colors: [Color(hex: 0x4A63E8), Color(hex: 0x1D2FA8)],
                        startPoint: .topLeading, endPoint: .bottomTrailing)),
                       dots: Theme.Colors.textHi)
        ]
    }

    /// Tapping a swatch sets the icon right here — no second screen for four
    /// self-evident choices.
    private var appIconSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("App icon".uppercased())
                .font(Theme.Typography.unitSuffix(12))
                .tracking(1.2)
                .foregroundStyle(Theme.Colors.textXlo)
                .padding(.horizontal, 8)
            HStack(spacing: 12) {
                ForEach(Array(iconOptions.enumerated()), id: \.offset) { idx, option in
                    iconSwatch(option, index: idx)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 4)
        }
    }

    private func iconSwatch(_ option: IconOption, index: Int) -> some View {
        let selected = selectedIcon == index
        return Button {
            Haptics.select()
            selectedIcon = index
            UIApplication.shared.setAlternateIconName(option.alternate) { error in
                if let error { print("App icon change failed: \(error.localizedDescription)") }
            }
        } label: {
            VStack(spacing: 6) {
                BrandDots(size: 26, color: option.dots)
                    .frame(width: 54, height: 54)
                    .background(option.ground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(selected ? Theme.Colors.butter : Color.white.opacity(0.12),
                                          lineWidth: selected ? 2 : 1)
                    )
                Text(option.name)
                    .font(Theme.Typography.caption())
                    .foregroundStyle(selected ? Theme.Colors.textHi : Theme.Colors.textXlo)
            }
        }
        .buttonStyle(PressableButtonStyle())
        .animation(Theme.Motion.quick, value: selected)
    }

    // MARK: Grouped card

    private func section(_ title: String, @ViewBuilder rows: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(Theme.Typography.unitSuffix(12))
                .tracking(1.2)
                .foregroundStyle(Theme.Colors.textXlo)
                .padding(.horizontal, 8)
            VStack(spacing: 0) { rows() }
                .background(Theme.Colors.slateCard,
                            in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.07), lineWidth: 1))
        }
    }

    private var divider: some View {
        Rectangle().fill(Color.white.opacity(0.06))
            .frame(height: 1)
            .padding(.leading, 62)
    }

    private enum RowAccessory { case chevron, value(String), none }

    private func slateRow(_ symbol: String, _ title: String,
                          accessory: RowAccessory = .chevron,
                          enabled: Bool = true,
                          action: @escaping () -> Void) -> some View {
        Button { if enabled { Haptics.tap(); action() } } label: {
            HStack(spacing: 13) {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .light))
                    .foregroundStyle(Theme.Colors.textHi)
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.06),
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                Text(title)
                    .font(Theme.Typography.value())
                    .foregroundStyle(Theme.Colors.textHi)
                Spacer(minLength: 0)
                switch accessory {
                case .chevron:
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.Colors.textLo)
                case .value(let v):
                    HStack(spacing: 10) {
                        Text(v).font(Theme.Typography.label())
                            .foregroundStyle(Theme.Colors.textLo)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.Colors.textLo)
                    }
                case .none:
                    EmptyView()
                }
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 54)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(enabled ? 1 : 0.45)
    }

    /// Invite shares the app link, so it's a ShareLink rather than a plain row.
    private var inviteRow: some View {
        ShareLink(item: URL(string: "https://rewire.app/download")!,
                  message: Text("Join me on Rewire — take back control.")) {
            HStack(spacing: 13) {
                Image(systemName: "arrowshape.turn.up.right")
                    .font(.system(size: 16, weight: .light))
                    .foregroundStyle(Theme.Colors.textHi)
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.06),
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                Text("Invite Friends")
                    .font(Theme.Typography.value())
                    .foregroundStyle(Theme.Colors.textHi)
                Spacer(minLength: 0)
                Image(systemName: "chevron.down")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Colors.textLo)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 54)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .simultaneousGesture(TapGesture().onEnded {
            Haptics.tap()
            gems.recordAchievement("share")
        })
    }

    // MARK: Premium card — the expected, low-risk paywall entry

    private var premiumCard: some View {
        Button { Haptics.tap(); showPaywall = true } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(gems.isPremium ? "Go Lifetime" : "Rewire Premium")
                        .font(Theme.Typography.headline())
                        .foregroundStyle(Color(hex: 0x141416))
                    Text(gems.isPremium ? "Pay once, keep it forever"
                                        : "Everything unlocked · \(SampleData.plans[1].subtitle.replacingOccurrences(of: "only ", with: ""))")
                        .font(Theme.Typography.caption())
                        .foregroundStyle(Color(hex: 0x141416).opacity(0.72))
                }
                Spacer(minLength: 0)
                Text(gems.isPremium ? "Upgrade" : "Upgrade")
                    .font(Theme.Typography.unitSuffix(14))
                    .foregroundStyle(Theme.Colors.textHi)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Color(hex: 0x141416), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(19)
            .background(
                LinearGradient(colors: [Theme.Colors.butter, Theme.Colors.primaryLo],
                               startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(PressableButtonStyle())
    }
}

#Preview { SettingsView().environment(GemStore()) }
