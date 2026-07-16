import SwiftUI

/// Settings tab (IMG_5467): an upsell banner, grouped preference/support/about
/// rows, and the plan chooser.
struct SettingsView: View {
    @Environment(GemStore.self) private var gems
    @Environment(\.openURL) private var openURL
    enum Route: Hashable { case appearance, appIcon }
    @State private var path: [Route] = []
    @State private var selectedPlan: Plan = SampleData.plans[1]   // annual — the anchor everywhere
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
        NavigationStack(path: $path) {
            ScrollView {
                    VStack(spacing: Theme.Spacing.xl) {
                        // Lifetime owners have nothing left to buy.
                        if gems.canUpgrade { upsellBanner }
                        group("Preferences", rows: [
                            SettingRow(symbol: "circle.lefthalf.filled", tint: .white,
                                       background: Theme.Colors.primary, title: "Appearance",
                                       accessory: .chevron) { path.append(.appearance) },
                            SettingRow(symbol: "checkmark.shield.fill", tint: Theme.Colors.greenDark,
                                       background: Theme.Colors.pastelLime, title: "App Icon",
                                       accessory: .chevron) { path.append(.appIcon) },
                            SettingRow(symbol: "app.badge", tint: .white,
                                       background: Theme.Colors.flame, title: "Daily Reminders",
                                       accessory: .chevron) { showReminders = true },
                            SettingRow(symbol: "faceid", tint: .white,
                                       background: Theme.Colors.green, title: "Face ID Lock",
                                       accessory: .chevron) { showFaceIDSettings = true },
                            SettingRow(symbol: "arrow.counterclockwise.circle", tint: .white,
                                       background: Theme.Colors.purple, title: "Data Backup",
                                       accessory: .chevron) { showDataBackup = true }
                        ])
                        supportUsGroup
                        group("About", rows: [
                            SettingRow(symbol: "doc.fill", tint: .white,
                                       background: Theme.Colors.blue, title: "Privacy Policy",
                                       accessory: .chevron) { openURL(Legal.privacyURL) },
                            SettingRow(symbol: "doc.text.fill", tint: .white,
                                       background: Theme.Colors.blue, title: "Terms of Service",
                                       accessory: .chevron) { openURL(Legal.termsURL) },
                            SettingRow(symbol: "arrow.counterclockwise.circle.fill", tint: .white,
                                       background: Theme.Colors.blue, title: "Restore Purchase",
                                       accessory: .none) { restorePurchase() },
                            SettingRow(symbol: "info.circle.fill", tint: .white,
                                       background: Color(hex: 0x4B5AD8), title: "Version Number",
                                       accessory: .value(appVersion)) {}
                        ])
                        // Premium users have nothing to buy — hide the chooser.
                        if !gems.isPremium { planSection }
                    }
                    .screenPadding()
                    .padding(.top, Theme.Spacing.lg)
                    .padding(.bottom, Theme.Spacing.tabBarClearance)
            }
            // Floating glass header — content scrolls underneath.
            .safeAreaInset(edge: .top) {
                NavHeader(title: "Settings") { CoinPill(count: gems.coins) }
                    .background { TopFadeScrim() }
            }
            .background(Theme.Colors.background)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .appearance: AppearanceView()
                case .appIcon:    AppIconView()
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallSheet().presentationDetents([.medium, .large])
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
        .tint(Theme.Colors.green)
    }

    private func restorePurchase() {
        gems.unlockPremium(plan: "1 year")   // mock restore — real plan comes with StoreKit
        Haptics.success()
        showRestoredAlert = true
    }

    /// Support group — Give Feedback is disabled (no mail composer wired up yet).
    /// Invite shares the app link, so it's a ShareLink rather than a SettingRow action.
    private var supportUsGroup: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader("Support us")
            VStack(spacing: 0) {
                SettingRow(symbol: "paperplane.fill", tint: .white,
                           background: Theme.Colors.blue, title: "Give Feedback",
                           accessory: .chevron, enabled: false)
                RowDivider(inset: 62)
                ShareLink(item: URL(string: "https://rewire.app/download")!,
                          message: Text("Join me on Rewire — take back control. 💪")) {
                    HStack(spacing: Theme.Spacing.md) {
                        IconSquare(symbol: "arrowshape.turn.up.right.fill", tint: .white,
                                   background: Theme.Colors.blue)
                        Text("Invite Friends")
                            .font(Theme.Typography.cardTitle())
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Spacer()
                    }
                    .padding(Theme.Spacing.md)
                }
                .buttonStyle(.plain)
                .simultaneousGesture(TapGesture().onEnded {
                    Haptics.tap()
                    gems.recordAchievement("share")
                })
            }
            .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
        }
    }

    private var upsellBanner: some View {
        Button { showPaywall = true } label: {
            HStack(spacing: Theme.Spacing.md) {
                IconSquare(symbol: "arrow.up.right", tint: Theme.Colors.greenDark,
                           background: Theme.Colors.pastelLime)
                VStack(alignment: .leading, spacing: 2) {
                    Text(gems.isPremium ? "Upgrade" : "Get the Full Effect")
                        .font(Theme.Typography.headline())
                        .foregroundStyle(Theme.Colors.green)
                    Text(gems.isPremium ? "Go Lifetime — pay once, keep it forever"
                                        : "Reach your goals faster 🔥")
                        .font(Theme.Typography.body())
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Theme.Colors.textTertiary)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
        }
        .buttonStyle(PressableButtonStyle())
    }

    private func group(_ title: String, rows: [SettingRow]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title)
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { idx, row in
                    row
                    if idx < rows.count - 1 { RowDivider(inset: 62) }
                }
            }
            .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
        }
    }

    private var planSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.sm) {
                TagBadge(kind: .plus)
                Text("Choose your plan")
                    .font(Theme.Typography.title())
                    .foregroundStyle(Theme.Colors.textPrimary)
            }
            VStack(spacing: Theme.Spacing.sm) {
                ForEach(SampleData.plans) { plan in
                    PlanCard(plan: plan, isSelected: selectedPlan == plan) { selectedPlan = plan }
                }
            }

            PrimaryButton(title: "Unlock Premium", trailingEmoji: "🙌") { showPaywall = true }
        }
    }
}

/// A single settings row (icon square + title + trailing accessory).
struct SettingRow: View {
    let symbol: String
    var tint: Color = .white
    var background: Color = Theme.Colors.primary
    let title: String
    enum Accessory { case chevron, none, value(String) }
    var accessory: Accessory = .chevron
    /// When false, the row reads as unavailable: dimmed, no chevron, taps do nothing.
    var enabled: Bool = true
    var action: () -> Void = {}

    var body: some View {
        Button(action: { if enabled { Haptics.tap(); action() } }) {
            HStack(spacing: Theme.Spacing.md) {
                IconSquare(symbol: symbol, tint: tint, background: background)
                Text(title)
                    .font(Theme.Typography.cardTitle())
                    .foregroundStyle(Theme.Colors.textPrimary)
                Spacer()
                if enabled {
                    switch accessory {
                    case .chevron:
                        Image(systemName: "chevron.right").foregroundStyle(Theme.Colors.textTertiary)
                    case .value(let v):
                        Text(v).font(Theme.Typography.body()).foregroundStyle(Theme.Colors.textSecondary)
                    case .none:
                        EmptyView()
                    }
                }
            }
            .padding(Theme.Spacing.md)
            .contentShape(Rectangle())   // whole tile tappable, not just text/icon
        }
        .buttonStyle(.plain)
        .opacity(enabled ? 1 : 0.45)
    }
}

#Preview { SettingsView().environment(GemStore()) }
