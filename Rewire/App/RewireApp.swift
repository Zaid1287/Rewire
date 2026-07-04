import SwiftUI

@main
struct RewireApp: App {
    @State private var appState = AppState()
    @State private var streakStore = StreakStore()
    @State private var gemStore = GemStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(streakStore)
                .environment(gemStore)
                .preferredColorScheme(.dark)
        }
    }
}
