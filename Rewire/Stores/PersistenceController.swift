import Foundation

/// The entire persisted app state in one Codable struct, written to
/// `Documents/rewire-state.json`. `elapsed`/timer are derived from `startDate`,
/// so they aren't stored. Badge/level progress is keyed by stable strings/ints,
/// not per-launch UUIDs.
struct AppSnapshot: Codable {
    // AppState
    var phase: AppState.Phase
    var quizAnswers: [Int]

    // StreakStore
    var startDate: Date
    var goal: Goal
    var recordSeconds: TimeInterval
    var reports: [DailyReport]
    var streaks: [Streak]
    var events: [StreakEvent]
    var challengeJoined: Bool
    var challengeDays: [ChallengeDay]

    // GemStore
    var gems: Int
    var coins: Int
    var isPremium: Bool
    var claimedBadges: Set<String>
    var likedSuperpowers: Set<String>
    var currentLevel: Int
    /// One-time special-offer deadline. Optional with a default so snapshots
    /// written before this field existed still decode.
    var offerDeadline: Date? = nil
}

/// Lightweight synchronous JSON persistence. `PersistenceController.shared`
/// holds the three stores; `scheduleSave()` debounces writes so a burst of
/// mutations (e.g. spring-animated awards) collapses to one disk write.
@MainActor
final class PersistenceController {
    static let shared = PersistenceController()

    private let url: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("rewire-state.json")
    }()

    private var appState: AppState?
    private var streak: StreakStore?
    private var gems: GemStore?
    private var saveWork: DispatchWorkItem?

    /// Wire stores, rehydrate from disk if a snapshot exists, then install the
    /// `persist` hooks. Call once from `RewireApp.init`.
    func configure(appState: AppState, streak: StreakStore, gems: GemStore) {
        self.appState = appState
        self.streak = streak
        self.gems = gems

        if let snapshot = Self.load(from: url) {
            appState.restore(from: snapshot)
            streak.restore(from: snapshot)
            gems.restore(from: snapshot)
        }

        let hook: () -> Void = { [weak self] in self?.scheduleSave() }
        appState.persist = hook
        streak.persist = hook
        gems.persist = hook
    }

    /// Debounced save — coalesces rapid mutations into a single write.
    func scheduleSave() {
        saveWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.saveNow() }
        saveWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
    }

    private func snapshot() -> AppSnapshot? {
        guard let appState, let streak, let gems else { return nil }
        return AppSnapshot(
            phase: appState.phase,
            quizAnswers: appState.quizAnswers,
            startDate: streak.startDate,
            goal: streak.goal,
            recordSeconds: streak.recordSeconds,
            reports: streak.reports,
            streaks: streak.streaks,
            events: streak.events,
            challengeJoined: streak.challengeJoined,
            challengeDays: streak.challengeDays,
            gems: gems.gems,
            coins: gems.coins,
            isPremium: gems.isPremium,
            claimedBadges: gems.claimedBadges,
            likedSuperpowers: gems.likedSuperpowers,
            currentLevel: gems.currentLevel,
            offerDeadline: gems.offerDeadline
        )
    }

    private func saveNow() {
        guard let snap = snapshot() else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(snap)
            try data.write(to: url, options: .atomic)
        } catch {
            // ponytail: best-effort local cache; a failed write just replays next mutation.
            print("PersistenceController save failed: \(error)")
        }
    }

    private static func load(from url: URL) -> AppSnapshot? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(AppSnapshot.self, from: data)
    }
}
