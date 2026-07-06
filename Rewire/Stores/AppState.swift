import SwiftUI

/// Top-level app phase — gates onboarding vs. the main tab bar.
@Observable
final class AppState {
    enum Phase: String, Codable { case onboarding, main }
    var phase: Phase = .onboarding { didSet { persist?() } }

    /// Currently selected main tab.
    var selectedTab: Tab = .home

    /// Onboarding quiz answers — one option index per question.
    private(set) var quizAnswers: [Int] = [] { didSet { persist?() } }

    /// Saver injected by RewireApp so mutations flush to disk.
    var persist: (() -> Void)?

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

    /// Record (or overwrite) the chosen option for a quiz question.
    func recordAnswer(questionIndex: Int, optionIndex: Int) {
        guard questionIndex >= 0 else { return }
        if quizAnswers.count <= questionIndex {
            quizAnswers += Array(repeating: 0, count: questionIndex - quizAnswers.count + 1)
        }
        quizAnswers[questionIndex] = optionIndex
    }

    /// Maps quiz answers to a 0–100 addiction score. Higher option index = worse.
    /// Scales the answer sum over the max possible, clamped to a plausible band.
    var addictionScore: Int {
        let questions = SampleData.quizQuestions
        let maxPossible = questions.reduce(0) { $0 + max(0, $1.options.count - 1) }
        guard maxPossible > 0 else { return 35 }
        let sum = quizAnswers.prefix(questions.count).reduce(0, +)
        let pct = Int((Double(sum) / Double(maxPossible)) * 100)
        return min(95, max(35, pct))
    }

    // MARK: Persistence

    func restore(from s: AppSnapshot) {
        phase = s.phase
        quizAnswers = s.quizAnswers
    }
}
