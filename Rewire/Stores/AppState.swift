import SwiftUI

/// Top-level app phase — gates onboarding vs. the main tab bar.
@Observable
final class AppState {
    enum Phase { case onboarding, main }
    var phase: Phase = .onboarding

    /// Currently selected main tab.
    var selectedTab: Tab = .home

    enum Tab: Int, CaseIterable {
        case home, quitPorn, recovery, history, settings
        var title: String {
            switch self {
            case .home: "Home"
            case .quitPorn: "Quit Porn"
            case .recovery: "Recovery"
            case .history: "History"
            case .settings: "Settings"
            }
        }
        var symbol: String {
            switch self {
            case .home: "house.fill"
            case .quitPorn: "shield.fill"
            case .recovery: "drop.fill"
            case .history: "clock.arrow.circlepath"
            case .settings: "gearshape.fill"
            }
        }
        /// Recovery tab shows a red "1" badge in the screenshots.
        var badgeCount: Int? { self == .recovery ? 1 : nil }
    }

    func finishOnboarding() {
        withAnimation(.easeInOut(duration: 0.4)) { phase = .main }
    }
}
