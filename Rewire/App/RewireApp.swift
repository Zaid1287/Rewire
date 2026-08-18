import SwiftUI

@main
struct RewireApp: App {
    @State private var appState = AppState()
    @State private var streakStore = StreakStore()
    @State private var gemStore = GemStore()
    @State private var shieldController = ShieldController()
    @State private var purchases = Purchases()

    @Environment(\.scenePhase) private var scenePhase

    init() {
        #if DEBUG
        // No test target; streak- and money-critical logic checks itself on
        // debug launch.
        StreakStore.selfCheck()
        Purchases.selfCheck()
        #endif
        Theme.Fonts.register()
        PersistenceController.shared.configure(
            appState: appState, streak: streakStore, gems: gemStore
        )
        Analytics.start()

        // StoreKit is the only writer of premium state — GemStore just caches
        // its answer so the rest of the app has one thing to read.
        let gems = gemStore
        purchases.onEntitlement = { active, productID in
            gems.applyEntitlement(active: active, productID: productID)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(streakStore)
                .environment(gemStore)
                .environment(shieldController)
                .environment(purchases)
                // Scenes are fixed per screen (RonLab): Home is Void, check-in
                // is Fog, stats are Ivory. There's nothing left for a light/dark
                // toggle to switch, so the app is pinned dark and the Appearance
                // setting is retired. `AppState.appearance` stays for snapshot
                // compatibility with older installs.
                .preferredColorScheme(.dark)
                .task { await purchases.load() }
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .active else { return }
                    // Drain any shield taps that happened while we were closed.
                    // No-op until the ShieldAction extension exists (S2), but
                    // wiring it now means S2 is extension-side only.
                    streakStore.ingestShieldEvents()
                    shieldController.refreshAuth()
                    // Renewals, expiries and refunds that happened while we were
                    // closed. Cheap, local, and it can revoke as well as grant.
                    Task { await purchases.refreshEntitlement() }
                    if ShieldEventStore.pendingReshield {
                        shieldController.apply()
                        ShieldEventStore.pendingReshield = false
                    }
                }
        }
    }
}
