import SwiftUI

/// Quit Porn tab (IMG_5458 / 5459): a hub of feature rows grouped into
/// Recommended / Boost your progress / Willpower / Privacy.
///
/// Row wiring: "Challenges" pushes the existing WeeklyChallengeView. Rows that
/// market a premium feature with no dedicated screen ("Power up your shield",
/// "Porn Blocker", "Private Support") present the shared PaywallSheet, which
/// already shows a "You're Premium" state once unlocked.
/// "Breathing Exercise" presents the shared PanicModeView breathing screen.
/// "My Motivations" presents MotivationsView. "21-day Personal Plan" pushes
/// PersonalPlanView, a day-by-day checklist backed by StreakStore.
/// "Reminder Notifications" presents ReminderSettingsView, wired to real
/// `UNUserNotificationCenter` scheduling. "Login via Face ID" presents
/// FaceIDSettingsView, wired to real `LocalAuthentication`. "Rewire Community"
/// opens the public Telegram group via `openURL`. "Data Backup" presents
/// DataBackupView (export/import the local snapshot). "Appearance Tracker"
/// pushes AppearanceTrackerView, a daily photo journal backed by AppState.
/// Everything else (Apple Watch) has no matching screen yet — those rows
/// carry `.soon` badges (dimmed, no chevron, no haptic) so they never read as
/// working controls.
struct QuitPornView: View {
    @Environment(GemStore.self) private var gems
    @Environment(\.openURL) private var openURL
    @State private var path: [Route] = []
    @State private var showPaywall = false
    @State private var showBreathing = false
    @State private var showMotivations = false
    @State private var showReminders = false
    @State private var showFaceIDSettings = false
    @State private var showDataBackup = false

    enum Route: Hashable { case challenge, personalPlan, appearance }

    /// Row titles that market a premium feature with no dedicated screen yet.
    private let premiumGatedTitles: Set<String> = [
        "Power up your shield", "Porn Blocker", "Private Support"
    ]

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                NavHeader(title: "Quit Porn")
                ScrollView {
                    VStack(spacing: Theme.Spacing.xl) {
                        group("Recommended", SampleData.quitRecommended, iconColor: Theme.Colors.green)
                        group("Boost your progress", SampleData.quitBoost)
                        group("Willpower", SampleData.quitWillpower)
                        group("Privacy", SampleData.quitPrivacy)
                    }
                    .screenPadding()
                    .padding(.top, Theme.Spacing.md)
                    .padding(.bottom, 120)
                }
            }
            .background(Theme.Colors.background)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .challenge: WeeklyChallengeView()
                case .personalPlan: PersonalPlanView()
                case .appearance: AppearanceTrackerView()
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallSheet().presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showBreathing) {
                PanicModeView()
                    .background(Theme.Colors.background)
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $showMotivations) {
                MotivationsView().presentationDetents([.large])
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
        }
        .tint(Theme.Colors.green)
    }

    private func group(_ title: String, _ items: [FeatureItem],
                       iconColor: Color = Theme.Colors.textPrimary) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title)
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                    FeatureRow(item: item,
                               iconColor: item.title.contains("Power up") ? Theme.Colors.green : iconColor,
                               action: { rowTapped(item) })
                        .padding(.horizontal, Theme.Spacing.md)
                    if idx < items.count - 1 { RowDivider(inset: 64) }
                }
            }
            .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
        }
    }

    private func rowTapped(_ item: FeatureItem) {
        if case .soon? = item.badge { return }
        if item.title == "Challenges" {
            path.append(.challenge)
        } else if item.title == "21-day Personal Plan" {
            path.append(.personalPlan)
        } else if item.title == "Appearance Tracker" {
            path.append(.appearance)
        } else if item.title == "Breathing Exercise" {
            showBreathing = true
        } else if item.title == "My Motivations" {
            showMotivations = true
        } else if item.title == "Reminder Notifications" {
            showReminders = true
        } else if item.title == "Login via Face ID" {
            showFaceIDSettings = true
        } else if item.title == "Rewire Community" {
            gems.recordAchievement("community")
            openURL(URL(string: "https://t.me/rewire_community")!)
        } else if item.title == "Data Backup" {
            showDataBackup = true
        } else if premiumGatedTitles.contains(item.title) {
            showPaywall = true
        }
        // Other rows have no destination yet — see the doc comment above.
    }
}

#Preview { QuitPornView().environment(GemStore()) }
