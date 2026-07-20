import SwiftUI

/// Toolkit tab (flow-redesign Phase 4, plan §1) — the old Quit Porn hub minus
/// the rows that were really settings (Reminders, Face ID, Data Backup moved
/// to Settings; the Apple Watch "soon" marketing row was cut).
///
/// Row wiring: "Challenges" pushes WeeklyChallengeView; "21-day Personal Plan"
/// pushes PersonalPlanView; "Appearance Tracker" pushes AppearanceTrackerView;
/// "Breathing Exercise" presents the shared PanicModeView; "My Motivations"
/// presents MotivationsView; "Power up your shield" pushes MyShieldView;
/// "Porn Blocker" pushes GuardSetupView (Screen Time shields, Phase S1).
/// Rows with no real screen yet ("Rewire Community", "Private Support") carry
/// `.soon` badges (dimmed, no chevron, no haptic) so they never read as
/// working controls.
struct ToolkitView: View {
    @State private var path: [Route] = []
    @State private var showBreathing = false
    @State private var showMotivations = false

    enum Route: Hashable { case challenge, personalPlan, appearance, shield, guardSetup }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    group("Recommended", SampleData.toolkitRecommended, iconColor: Theme.Colors.green)
                    group("Boost your progress", SampleData.toolkitBoost)
                    group("Willpower", SampleData.toolkitWillpower)
                }
                .screenPadding()
                .padding(.top, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.tabBarClearance)
            }
            .collapsesDock()
            // Floating glass header — content scrolls underneath.
            .safeAreaInset(edge: .top) {
                NavHeader(title: "Toolkit")
                    .background { TopFadeScrim() }
            }
            .background(Theme.Colors.background)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .challenge: WeeklyChallengeView()
                case .personalPlan: PersonalPlanView()
                case .appearance: AppearanceTrackerView()
                case .shield: MyShieldView()
                case .guardSetup: GuardSetupView()
                }
            }
            .sheet(isPresented: $showBreathing) {
                PanicModeView()
                    .background(Theme.Colors.background)
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $showMotivations) {
                MotivationsView().presentationDetents([.large])
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
        if item.title == "Power up your shield" {
            path.append(.shield)
        } else if item.title == "Challenges" {
            path.append(.challenge)
        } else if item.title == "21-day Personal Plan" {
            path.append(.personalPlan)
        } else if item.title == "Appearance Tracker" {
            path.append(.appearance)
        } else if item.title == "Porn Blocker" {
            path.append(.guardSetup)
        } else if item.title == "Breathing Exercise" {
            showBreathing = true
        } else if item.title == "My Motivations" {
            showMotivations = true
        }
        // Other rows have no destination yet — see the doc comment above.
    }
}

#Preview {
    ToolkitView()
        .environment(GemStore())
        .environment(AppState())
        .environment(ShieldController())
}
