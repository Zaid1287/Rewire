import SwiftUI

@main
struct RewireApp: App {
    @State private var appState = AppState()
    @State private var streakStore = StreakStore()
    @State private var gemStore = GemStore()
    @State private var shieldController = ShieldController()

    @Environment(\.scenePhase) private var scenePhase

    init() {
        PersistenceController.shared.configure(
            appState: appState, streak: streakStore, gems: gemStore
        )
        Analytics.start()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(streakStore)
                .environment(gemStore)
                .environment(shieldController)
                .preferredColorScheme(appState.appearance.colorScheme)
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .active else { return }
                    // Drain any shield taps that happened while we were closed.
                    // No-op until the ShieldAction extension exists (S2), but
                    // wiring it now means S2 is extension-side only.
                    streakStore.ingestShieldEvents()
                    shieldController.refreshAuth()
                    if ShieldEventStore.pendingReshield {
                        shieldController.apply()
                        ShieldEventStore.pendingReshield = false
                    }
                }
        }
    }
}
