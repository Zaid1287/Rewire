import SwiftUI

/// Settings tab (IMG_5467): an upsell banner, grouped preference/support/about
/// rows, and the plan chooser.
struct SettingsView: View {
    @Environment(GemStore.self) private var gems
    @Environment(\.openURL) private var openURL
    enum Route: Hashable { case appearance, appIcon }
    @State private var path: [Route] = []
    @State private var selectedPlan: Plan = SampleData.plans[0]
    @State private var showPaywall = false
    @State private var showRestoredAlert = false

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                NavHeader(title: "Settings") { CoinPill(count: gems.coins) }
                ScrollView {
                    VStack(spacing: Theme.Spacing.xl) {
                        upsellBanner
                        group("Preferences", rows: [
                            SettingRow(symbol: "circle.lefthalf.filled", tint: .white,
                                       background: Theme.Colors.primary, title: "Appearance",
                                       accessory: .chevron) { path.append(.appearance) },
                            SettingRow(symbol: "checkmark.shield.fill", tint: Color(hex: 0x2E7D32),
                                       background: Color(hex: 0xB6E8A0), title: "App Icon",
                                       accessory: .chevron) { path.append(.appIcon) }
                        ])
                        supportUsGroup
                        group("About", rows: [
                            SettingRow(symbol: "doc.fill", tint: .white,
                                       background: Color(hex: 0x2C6BE0), title: "Privacy Policy",
                                       accessory: .chevron) { openURL(URL(string: "https://rewire.app/privacy")!) },
                            SettingRow(symbol: "arrow.counterclockwise.circle.fill", tint: .white,
                                       background: Color(hex: 0x2C6BE0), title: "Restore Purchase",
                                       accessory: .none) { restorePurchase() },
                            SettingRow(symbol: "info.circle.fill", tint: .white,
                                       background: Color(hex: 0x4B5AD8), title: "Version Number",
                                       accessory: .value(appVersion)) {}
                        ])
                        planSection
                    }
                    .screenPadding()
                    .padding(.top, Theme.Spacing.lg)
                    .padding(.bottom, 120)
                }
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
            .overlay {
                if showRestoredAlert {
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
        }
        .tint(Theme.Colors.green)
    }

    private func restorePurchase() {
        gems.unlockPremium()
        Haptics.success()
        showRestoredAlert = true
    }

    /// Support group — Feedback opens the mail composer via mailto:, Invite
    /// shares the app link, so it's a ShareLink rather than a SettingRow action.
    private var supportUsGroup: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader("Support us")
            VStack(spacing: 0) {
                SettingRow(symbol: "paperplane.fill", tint: .white,
                           background: Color(hex: 0x2C6BE0), title: "Give Feedback",
                           accessory: .chevron) {
                    gems.recordAchievement("feedback")
                    openURL(URL(string: "mailto:support@rewire.app?subject=Rewire%20Feedback")!)
                }
                RowDivider(inset: 62)
                ShareLink(item: URL(string: "https://rewire.app/download")!,
                          message: Text("Join me on Rewire — take back control. 💪")) {
                    HStack(spacing: Theme.Spacing.md) {
                        IconSquare(symbol: "arrowshape.turn.up.right.fill", tint: .white,
                                   background: Color(hex: 0x2C6BE0))
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
                IconSquare(symbol: "arrow.up.right", tint: Color(hex: 0x2E7D32),
                           background: Color(hex: 0xB6E8A0))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Get the Full Effect")
                        .font(Theme.Typography.headline())
                        .foregroundStyle(Theme.Colors.green)
                    Text("Reach your goals faster 🔥")
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
            VStack(spacing: 0) {
                ForEach(Array(SampleData.plans.enumerated()), id: \.element.id) { idx, plan in
                    PlanRow(plan: plan, isSelected: selectedPlan == plan) { selectedPlan = plan }
                    if idx < SampleData.plans.count - 1 { RowDivider(inset: Theme.Spacing.lg) }
                }
            }
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.lg).stroke(Theme.Colors.divider, lineWidth: 1))

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
    var action: () -> Void = {}

    var body: some View {
        Button(action: { Haptics.tap(); action() }) {
            HStack(spacing: Theme.Spacing.md) {
                IconSquare(symbol: symbol, tint: tint, background: background)
                Text(title)
                    .font(Theme.Typography.cardTitle())
                    .foregroundStyle(Theme.Colors.textPrimary)
                Spacer()
                switch accessory {
                case .chevron:
                    Image(systemName: "chevron.right").foregroundStyle(Theme.Colors.textTertiary)
                case .value(let v):
                    Text(v).font(Theme.Typography.body()).foregroundStyle(Theme.Colors.textSecondary)
                case .none:
                    EmptyView()
                }
            }
            .padding(Theme.Spacing.md)
        }
        .buttonStyle(.plain)
    }
}

#Preview { SettingsView().environment(GemStore()) }
