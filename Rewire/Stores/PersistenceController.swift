import Foundation

/// The entire persisted app state in one Codable struct, written to
/// `Documents/rewire-state.json`. `elapsed`/timer are derived from `startDate`,
/// so they aren't stored. Badge/level progress is keyed by stable strings/ints,
/// not per-launch UUIDs.
struct AppSnapshot: Codable {
    // AppState
    var phase: AppState.Phase
    var quizAnswers: [Int]
    /// Optional with a default so snapshots written before this field existed
    /// still decode.
    var motivations: [Motivation]? = nil
    /// Appearance Tracker photo journal. Optional with a default so snapshots
    /// written before this field existed still decode.
    var appearancePhotos: [AppearancePhoto]? = nil
    /// Daily reminder settings. Optional with a default so snapshots written
    /// before this field existed still decode.
    var reminderEnabled: Bool? = nil
    /// Analytics consent. Optional with a default so snapshots written before
    /// it existed decode — and absent means off, which is the safe direction.
    var analyticsOptIn: Bool? = nil
    /// iCloud backup consent. Optional with a default; absent means off.
    var cloudSyncOptIn: Bool? = nil
    var reminderHour: Int? = nil
    var reminderMinute: Int? = nil
    /// Face ID app-lock. Optional with a default so snapshots written before
    /// this field existed still decode.
    var faceIDEnabled: Bool? = nil
    /// Appearance preference (system/light/dark). Optional with a default so
    /// snapshots written before this field existed still decode.
    var appearance: AppState.Appearance? = nil

    // StreakStore
    var startDate: Date
    var goal: Goal
    var recordSeconds: TimeInterval
    var reports: [DailyReport]
    var streaks: [Streak]
    var events: [StreakEvent]
    /// Legacy: a permanent "joined once" bool, before joining became weekly.
    /// Optional with a default so both old and new snapshots decode.
    var challengeJoined: Bool? = nil
    /// The week the user last joined, e.g. "2026-W34".
    var challengeWeek: String? = nil
    var hasEverJoinedChallenge: Bool? = nil
    /// 21-day Personal Plan completion. Optional with a default so snapshots
    /// written before this field existed still decode.
    var completedPlanDays: Set<Int>? = nil

    // GemStore
    var isPremium: Bool
    var claimedBadges: Set<String>
    /// Misc one-off unlocks. Optional with a default so snapshots written
    /// before this field existed still decode.
    var achievements: Set<String>? = nil
    /// Purchased plan title. Optional with a default so snapshots written
    /// before this field existed still decode.
    var premiumPlan: String? = nil

    // AppState — motivation reminders. Optional with defaults so snapshots
    // written before these fields existed still decode.
    var motivationRemindersEnabled: Bool? = nil
    var motivationsPerDay: Int? = nil

    // MARK: Sync bookkeeping
    /// When this snapshot was last written, used by `CloudSync.merge` to decide
    /// which side wins for scalar fields. Optional with a default so snapshots
    /// written before sync existed decode — `nil` sorts oldest, which is the
    /// safe direction (a snapshot that never knew about sync never overwrites
    /// one that did).
    var updatedAt: Date? = nil
}

#if DEBUG
extension AppSnapshot {
    /// Minimal valid snapshot for `CloudSync.selfCheck`. Debug only — never a
    /// source of app data.
    static var selfCheckFixture: AppSnapshot {
        AppSnapshot(phase: .main,
                    quizAnswers: [],
                    startDate: Date(timeIntervalSince1970: 0),
                    goal: Goal(label: "fixture", seconds: 60),
                    recordSeconds: 0,
                    reports: [],
                    streaks: [],
                    events: [],
                    isPremium: false,
                    claimedBadges: [])
    }
}
#endif

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
        streak.syncWidget()   // seed the widget on launch
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
            motivations: appState.motivations,
            appearancePhotos: appState.appearancePhotos,
            reminderEnabled: appState.reminderEnabled,
            analyticsOptIn: appState.analyticsOptIn,
            cloudSyncOptIn: appState.cloudSyncOptIn,
            reminderHour: appState.reminderHour,
            reminderMinute: appState.reminderMinute,
            faceIDEnabled: appState.faceIDEnabled,
            appearance: appState.appearance,
            startDate: streak.startDate,
            goal: streak.goal,
            recordSeconds: streak.recordSeconds,
            reports: streak.reports,
            streaks: streak.streaks,
            events: streak.events,
            challengeWeek: streak.challengeWeek,
            hasEverJoinedChallenge: streak.hasEverJoinedChallenge,
            completedPlanDays: streak.completedPlanDays,
            isPremium: gems.isPremium,
            claimedBadges: gems.claimedBadges,
            achievements: gems.achievements,
            premiumPlan: gems.premiumPlan,
            motivationRemindersEnabled: appState.motivationRemindersEnabled,
            motivationsPerDay: appState.motivationsPerDay,
            updatedAt: Date()
        )
    }

    /// The current state, for CloudSync to push. Same builder the disk write
    /// uses, so the two can never drift apart.
    func currentSnapshot() -> AppSnapshot? { snapshot() }

    /// Documents/rewire-state.json — exposed for the Data Backup export sheet.
    var backupURL: URL { url }

    /// Force an immediate (non-debounced) save. Used before sharing the backup
    /// file so the export reflects the latest state.
    func flush() { saveNow() }

    /// Restore all stores from an imported snapshot (Data Backup import), then
    /// persist immediately so it survives a relaunch.
    func restoreAll(from snapshot: AppSnapshot) {
        appState?.restore(from: snapshot)
        streak?.restore(from: snapshot)
        gems?.restore(from: snapshot)
        saveNow()
    }

    private func saveNow() {
        guard let snap = snapshot() else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(snap)
            // completeUntilFirstUserAuthentication: relapse/report history is
            // sensitive — encrypted at rest without breaking saves that fire
            // during background transitions.
            try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        } catch {
            // ponytail: best-effort local cache; a failed write just replays next mutation.
            print("PersistenceController save failed: \(error)")
        }
    }

    private static func load(from url: URL) -> AppSnapshot? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        do {
            return try decode(data)
        } catch {
            // Don't let the next save silently overwrite a corrupt-but-maybe-
            // recoverable state file — move it aside first.
            let quarantine = url.deletingLastPathComponent()
                .appendingPathComponent("rewire-state.corrupt.json")
            try? FileManager.default.removeItem(at: quarantine)
            try? FileManager.default.moveItem(at: url, to: quarantine)
            return nil
        }
    }

    /// Shared decoder settings, also used by the Data Backup import flow.
    static func decode(_ data: Data) throws -> AppSnapshot {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(AppSnapshot.self, from: data)
    }
}
