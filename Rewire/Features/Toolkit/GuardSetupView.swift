import SwiftUI
import FamilyControls

/// Porn Blocker setup (Toolkit → "Porn Blocker") — Phase S1.
///
/// Hero-led, one primary action per state, so the flow reads as a single path
/// (turn on → pick → guarding) instead of three loose controls. Deliberately
/// has no "Scheduled" mode yet: Always is the honest default, and schedules
/// need the DeviceActivity extension (S3) to arm with Rewire closed — shipping
/// a schedule the app can't keep would be a lie in the UI.
///
/// The shield the user sees on a guarded app is iOS's default one until the
/// ShieldUI extension lands (S2) — that's when it becomes Rewire-branded with
/// the "Not this time" / "I relapsed" buttons.
struct GuardSetupView: View {
    @Environment(ShieldController.self) private var guardController
    @Environment(\.dismiss) private var dismiss

    @State private var showPicker = false

    var body: some View {
        @Bindable var guardController = guardController

        VStack(spacing: 0) {
            NavHeader(title: "Porn Blocker", showsBack: true, onBack: { dismiss() })

            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    switch guardController.auth {
                    case .unknown: notAuthorized
                    case .denied(let reason): denied(reason)
                    case .approved:
                        if guardController.hasSelection { guarding(guardController) }
                        else { emptyAuthorized }
                    }
                }
                .screenPadding()
                .padding(.top, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.tabBarClearance)
            }
            .collapsesDock()
        }
        .background { SceneBackground(kind: .void) }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .familyActivityPicker(isPresented: $showPicker, selection: $guardController.selection)
        .onChange(of: guardController.selection) { guardController.selectionChanged() }
        // Screen Time access can be revoked in Settings while we're backgrounded.
        .onAppear { guardController.refreshAuth() }
    }

    // MARK: States

    private var notAuthorized: some View {
        VStack(spacing: Theme.Spacing.xl) {
            hero(icon: "checkmark.shield.fill",
                 tint: Theme.Colors.good,
                 title: "Block porn apps & sites",
                 subtitle: "Pick what you don't want to open. When you reach for it, Rewire stops you at the door.")

            howItWorks

            PrimaryButton(title: "Turn on blocker") {
                Task {
                    await guardController.requestAuth()
                    // Straight into the picker on approval — one continuous flow,
                    // not "granted, now find the next button".
                    if guardController.isAuthorized { showPicker = true }
                }
            }
            .disabled(guardController.requesting)
            .overlay { if guardController.requesting { ProgressView().tint(.white) } }

            privacyNote
        }
    }

    private var emptyAuthorized: some View {
        VStack(spacing: Theme.Spacing.xl) {
            hero(icon: "shield.slash.fill",
                 tint: Theme.Colors.textTertiary,
                 title: "Nothing guarded yet",
                 subtitle: "Choose the apps and websites to block. You can change them anytime.")

            howItWorks

            PrimaryButton(title: "Choose what to block") { showPicker = true }

            privacyNote
        }
    }

    private func guarding(_ guardController: ShieldController) -> some View {
        VStack(spacing: Theme.Spacing.xl) {
            hero(icon: guardController.enabled ? "checkmark.shield.fill" : "shield.slash.fill",
                 tint: guardController.enabled ? Theme.Colors.good : Theme.Colors.textTertiary,
                 title: guardController.enabled ? "Blocker is on" : "Blocker is off",
                 subtitle: guardController.enabled
                    ? "Guarding \(selectionSummary). Reaching for one shows the shield."
                    : "You're guarding \(selectionSummary), but the blocker is switched off.")

            // On/off — the primary control once something is selected.
            HStack(spacing: Theme.Spacing.md) {
                IconCircle(symbol: "power",
                           tint: guardController.enabled ? Theme.Colors.good : Theme.Colors.textSecondary,
                           background: Theme.Colors.surface2, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Blocker")
                        .font(Theme.Typography.headline())
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text(guardController.enabled ? "On" : "Off")
                        .font(Theme.Typography.subtitle())
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                Spacer(minLength: 0)
                Toggle("", isOn: Binding(
                    get: { guardController.enabled },
                    set: { guardController.setEnabled($0) }
                ))
                .labelsHidden()
                .tint(Theme.Colors.good)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))

            Button { showPicker = true } label: {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "slider.horizontal.3")
                    Text("Edit what's blocked")
                }
                .font(Theme.Typography.button())
                .foregroundStyle(Theme.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(Theme.Colors.surface, in: Capsule())
            }
            .buttonStyle(PressableButtonStyle())

            privacyNote
        }
    }

    private func denied(_ reason: String) -> some View {
        VStack(spacing: Theme.Spacing.xl) {
            hero(icon: "exclamationmark.shield.fill",
                 tint: Theme.Colors.butter,
                 title: "Screen Time access is off",
                 subtitle: "The blocker needs it. Everything else in Rewire works without it — turn it on and come back.")

            PrimaryButton(title: "Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }

            Text(reason)
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Colors.textTertiary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    // MARK: Pieces

    private func hero(icon: String, tint: Color, title: String, subtitle: String) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            IconCircle(symbol: icon, tint: tint, background: Theme.Colors.surface, size: 88)
            Text(title)
                .font(Theme.Typography.title())
                .foregroundStyle(Theme.Colors.textPrimary)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(Theme.Typography.body())
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Theme.Spacing.md)
    }

    private var howItWorks: some View {
        VStack(spacing: 0) {
            infoRow("hand.tap.fill", "One tap to pick",
                    "Choose apps, whole categories, or specific websites.")
            RowDivider(inset: 64)
            infoRow("shield.lefthalf.filled", "Blocked at the door",
                    "Opening a guarded app shows a shield instead.")
            RowDivider(inset: 64)
            infoRow("lock.fill", "Stays private",
                    "iOS keeps your choices on-device. Rewire never sees them.")
        }
        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
    }

    private func infoRow(_ symbol: String, _ title: String, _ subtitle: String) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            IconCircle(symbol: symbol, tint: Theme.Colors.good,
                       background: Theme.Colors.surface2, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.Typography.headline())
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text(subtitle)
                    .font(Theme.Typography.subtitle())
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(Theme.Spacing.md)
    }

    private var privacyNote: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "lock.shield")
            Text("Rewire never sees which apps or sites you pick.")
        }
        .font(Theme.Typography.caption())
        .foregroundStyle(Theme.Colors.textTertiary)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    /// Counts only — the tokens are opaque, so there are no names to show even
    /// if we wanted them.
    private var selectionSummary: String {
        let apps = guardController.selection.applicationTokens.count
        let categories = guardController.selection.categoryTokens.count
        let sites = guardController.selection.webDomainTokens.count
        var parts: [String] = []
        if apps > 0 { parts.append("\(apps) app\(apps == 1 ? "" : "s")") }
        if categories > 0 { parts.append("\(categories) categor\(categories == 1 ? "y" : "ies")") }
        if sites > 0 { parts.append("\(sites) site\(sites == 1 ? "" : "s")") }
        return parts.isEmpty ? "nothing yet" : parts.joined(separator: " · ")
    }
}
