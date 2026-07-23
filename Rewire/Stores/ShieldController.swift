import SwiftUI
import FamilyControls
import ManagedSettings

/// Owns the Screen Time guard: permission, which apps/sites the user chose, and
/// applying the shields (Phase S1).
///
/// The selection lives in the App Group rather than the app's own snapshot
/// because the shield extensions need to read it too — and because
/// `FamilyActivitySelection`'s tokens are opaque, they're only meaningful to
/// Apple's frameworks, never to us. We never see which apps these are, which is
/// the privacy story working as intended, not a limitation to route around.
@Observable
final class ShieldController {
    enum Auth: Equatable { case unknown, approved, denied(String) }

    private(set) var auth: Auth = .unknown
    /// True while the system authorization round-trip is in flight — the first
    /// call hits Apple's servers and can take several seconds, so the UI must
    /// show progress or the button reads as dead.
    private(set) var requesting = false
    /// Empty until `load()` — persisted across launches via the App Group.
    var selection = FamilyActivitySelection()
    private(set) var enabled = false

    /// Self-binding commitment (see `CommitmentLock`). While it binds, the
    /// blocker can't be switched off or narrowed — only strengthened.
    private(set) var lock = CommitmentLock()
    /// What was guarded when the commitment started. Restoring from this is how
    /// "you may add, you may not remove" is enforced against the picker, which
    /// hands us an already-mutated selection.
    private var committedSelection: FamilyActivitySelection?

    // ponytail: the default store. Named stores only matter once schedules need
    // to shield different sets at different times — that's S3's problem.
    private let store = ManagedSettingsStore()

    private static let selectionKey = "guard.selection"
    private static let enabledKey = "guard.enabled"
    private static let lockKey = "guard.lock"
    private static let committedSelectionKey = "guard.lock.selection"

    init() { load() }

    #if DEBUG
    /// Simulator escape hatch. Screen Time authorization needs a device
    /// passcode the Simulator can't supply, which otherwise makes the whole
    /// guarded UI — and every commitment-lock state — unreachable outside a
    /// real device. Launch with `REWIRE_FAKE_GUARD=1` to walk the real flow.
    /// Only fakes the *system* edges (auth, selection, applying shields); all
    /// lock logic below runs exactly as it does in production.
    static let fakeGuard = ProcessInfo.processInfo.environment["REWIRE_FAKE_GUARD"] != nil
    #else
    static let fakeGuard = false
    #endif

    var isAuthorized: Bool { auth == .approved }

    /// Reflects the real state — a user can revoke Screen Time in Settings at
    /// any time, so trusting a stored flag would strand us shielding nothing.
    func refreshAuth() {
        if Self.fakeGuard { auth = .approved; return }
        switch AuthorizationCenter.shared.authorizationStatus {
        case .approved: auth = .approved
        case .denied: auth = .denied("Screen Time access was denied.")
        default: auth = .unknown
        }
    }

    func requestAuth() async {
        guard !requesting else { return }
        requesting = true
        defer { requesting = false }
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            auth = .approved
        } catch {
            // Denial is a normal outcome, not a failure: the rest of Rewire must
            // keep working, so this only marks the guard unavailable.
            auth = .denied(error.localizedDescription)
        }
    }

    /// True when the user picked at least one thing to guard. An empty selection
    /// with the toggle on would shield nothing while claiming to be protecting
    /// them — worse than being off.
    var hasSelection: Bool {
        if Self.fakeGuard { return true }
        return !selection.applicationTokens.isEmpty
            || !selection.categoryTokens.isEmpty
            || !selection.webDomainTokens.isEmpty
    }

    // MARK: Commitment lock

    var lockState: CommitmentLock.State { lock.state() }
    /// True while the blocker may not be switched off or narrowed.
    var isBound: Bool { lock.binds() }

    /// Start a commitment. Snapshots what's guarded so the picker can't be used
    /// to quietly empty the selection instead of flipping the toggle.
    func commit(for duration: TimeInterval) {
        guard hasSelection else { return }
        // Committing implies the blocker is on. Returning silently when it
        // wasn't made "Lock it in" a button that could do nothing at all,
        // with no feedback — turn it on instead.
        if !enabled { setEnabled(true) }
        lock.commit(for: duration)
        committedSelection = selection
        save()
    }

    func requestUnlock() { lock.requestUnlock(); save() }
    func cancelUnlockRequest() { lock.cancelUnlockRequest(); save() }

    /// Drop the commitment. Only legal once the wait has been served (or the
    /// commitment has run out) — `setEnabled` is the gate, this is the effect.
    private func releaseLock() {
        lock.release()
        committedSelection = nil
    }

    func setEnabled(_ on: Bool) {
        // Turning ON is never restricted — strengthening is always allowed.
        if !on && isBound { return }
        // Switching off during the open window spends the commitment.
        if !on { releaseLock() }
        enabled = on && hasSelection
        enabled ? apply() : clear()
        save()
    }

    /// Re-apply after a selection change, but only while the guard is on.
    func selectionChanged() {
        // While bound, additions stick and removals are undone: union the
        // current pick back over the committed one.
        if isBound, let committed = committedSelection {
            selection.applicationTokens.formUnion(committed.applicationTokens)
            selection.categoryTokens.formUnion(committed.categoryTokens)
            selection.webDomainTokens.formUnion(committed.webDomainTokens)
        }
        if enabled && !hasSelection { enabled = false }
        enabled ? apply() : clear()
        save()
    }

    func apply() {
        // Without real authorization the store rejects writes, so skip it.
        if Self.fakeGuard { return }
        // nil, not an empty set: an empty set is a valid "shield exactly these
        // zero things" and leaves the previous shield in place on some paths.
        store.shield.applications =
            selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories =
            selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        store.shield.webDomains =
            selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
    }

    func clear() {
        if Self.fakeGuard { return }
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }

    // MARK: Persistence (App Group — the extensions read this later)

    private func save() {
        let defaults = UserDefaults(suiteName: ShieldEventStore.appGroup)
        defaults?.set(enabled, forKey: Self.enabledKey)
        if let data = try? JSONEncoder().encode(selection) {
            defaults?.set(data, forKey: Self.selectionKey)
        }
        // The lock is only a commitment if it outlives a force-quit.
        if let data = try? JSONEncoder().encode(lock) {
            defaults?.set(data, forKey: Self.lockKey)
        }
        if let committedSelection, let data = try? JSONEncoder().encode(committedSelection) {
            defaults?.set(data, forKey: Self.committedSelectionKey)
        } else if committedSelection == nil {
            defaults?.removeObject(forKey: Self.committedSelectionKey)
        }
    }

    private func load() {
        let defaults = UserDefaults(suiteName: ShieldEventStore.appGroup)
        enabled = defaults?.bool(forKey: Self.enabledKey) ?? false
        if let data = defaults?.data(forKey: Self.selectionKey),
           let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            selection = saved
        }
        if let data = defaults?.data(forKey: Self.lockKey),
           let saved = try? JSONDecoder().decode(CommitmentLock.self, from: data) {
            lock = saved
        }
        if let data = defaults?.data(forKey: Self.committedSelectionKey),
           let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            committedSelection = saved
        }
    }
}
