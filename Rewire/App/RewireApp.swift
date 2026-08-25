import SwiftUI

@main
struct RewireApp: App {
    @State private var appState = AppState()
    @State private var streakStore = StreakStore()
    @State private var gemStore = GemStore()
    @State private var shieldController = ShieldController()
    @State private var purchases = Purchases()
    @State private var cloudSync = CloudSync()

    @Environment(\.scenePhase) private var scenePhase

    init() {
        #if DEBUG
        // No test target; streak- and money-critical logic checks itself on
        // debug launch.
        StreakStore.selfCheck()
        Purchases.selfCheck()
        Analytics.selfCheck()
        CloudSync.selfCheck()
        #endif
        Theme.Fonts.register()
        PersistenceController.shared.configure(
            appState: appState, streak: streakStore, gems: gemStore
        )
        // Consent is restored from the snapshot by configure() above, so this
        // reads the user's actual answer rather than defaulting to on.
        Analytics.start(optedIn: appState.analyticsOptIn)

        let gems = gemStore

        #if DEBUG
        // Lets a debug run see the Premium side of the four gates without a
        // sandbox purchase: REWIRE_PREMIUM=1. It has to intercept the
        // entitlement callback rather than just set the flag once — StoreKit
        // refreshes moments after launch and would immediately overwrite it
        // with active: false. Still routed through applyEntitlement (the one
        // writer), and compiled out of Release entirely.
        let forcePremium = ProcessInfo.processInfo.environment["REWIRE_PREMIUM"] == "1"
        if forcePremium {
            gems.applyEntitlement(active: true, productID: Purchases.ProductID.yearly)
        }
        #endif

        // StoreKit is the only writer of premium state — GemStore just caches
        // its answer so the rest of the app has one thing to read.
        purchases.onEntitlement = { active, productID in
            #if DEBUG
            if forcePremium {
                gems.applyEntitlement(active: true, productID: Purchases.ProductID.yearly)
                return
            }
            #endif
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
                .environment(cloudSync)
                // Scenes are fixed per screen (RonLab): Home is Void, check-in
                // is Fog, stats are Ivory. There's nothing left for a light/dark
                // toggle to switch, so the app is pinned dark and the Appearance
                // setting is retired. `AppState.appearance` stays for snapshot
                // compatibility with older installs.
                .preferredColorScheme(.dark)
                .task {
                    await purchases.load()
                    await cloudSync.syncIfEnabled(optedIn: appState.cloudSyncOptIn)
                }
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
                    // Pull anything another device recorded while we were away.
                    Task { await cloudSync.syncIfEnabled(optedIn: appState.cloudSyncOptIn) }
                    if ShieldEventStore.pendingReshield {
                        shieldController.apply()
                        ShieldEventStore.pendingReshield = false
                    }
                }
        }
    }
}
