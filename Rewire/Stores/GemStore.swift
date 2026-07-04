import SwiftUI

/// Gamification currency shown in the top-right pill across the app
/// (gems + coins). Onboarding awards gems as the quiz progresses (100 → 750).
@Observable
final class GemStore {
    var gems: Int = 750     // ends onboarding at 750 per the Home header
    var coins: Int = 0

    func award(_ amount: Int) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            gems += amount
        }
    }

    func spend(_ amount: Int) {
        gems = max(0, gems - amount)
    }
}
