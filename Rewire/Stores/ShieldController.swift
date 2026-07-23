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

    /// Sites the user vouched for after the filter got one wrong. Without this,
    /// a false positive leaves only one way out — switching the whole blocker
    /// off — and reviewers of the app we're replacing describe exactly that
    /// ending in it staying off for good.
    private(set) var allowedDomains: Set<String> = []
    /// Sites to block on top of Apple's list, for what it misses.
    private(set) var blockedDomains: Set<String> = []

    // ponytail: the default store. Named stores only matter once schedules need
    // to shield different sets at different times — that's S3's problem.
    private let store = ManagedSettingsStore()

    private static let selectionKey = "guard.selection"
    private static let enabledKey = "guard.enabled"
    private static let lockKey = "guard.lock"
    private static let committedSelectionKey = "guard.lock.selection"
    private static let allowedKey = "guard.allowed"
    private static let blockedKey = "guard.blocked"

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

    /// True when the user picked specific apps or sites to shield on top of the
    /// filter. It no longer gates turning the blocker on: the web filter
    /// protects an empty selection perfectly well, and requiring a pick first
    /// meant a user could switch the blocker "on" and be given nothing.
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

    // MARK: Site exceptions

    enum ExceptionResult: Equatable {
        case ok
        /// The input wasn't a usable host.
        case invalidDomain
        /// Refused because a commitment is running.
        case locked
    }

    /// Vouch for a site the filter got wrong.
    ///
    /// This is a *weakening* edit, so a commitment refuses it. That isn't
    /// pedantry: the app we're replacing shipped a free-form allow list and
    /// earned a one-star review for it — *"there's an allowed website? Just
    /// place the porn website you want and you get complete access."* Allowing
    /// arbitrary hosts mid-commitment would rebuild exactly that hole.
    @discardableResult
    func allow(_ raw: String) -> ExceptionResult {
        guard let domain = DomainInput.normalize(raw) else { return .invalidDomain }
        if isBound { return .locked }
        allowedDomains.insert(domain)
        blockedDomains.remove(domain)
        if enabled { apply() }
        save()
        return .ok
    }

    /// Withdraw a vouch — strengthening, so always permitted.
    func removeAllowed(_ domain: String) {
        allowedDomains.remove(domain)
        if enabled { apply() }
        save()
    }

    /// Block something Apple's list misses — strengthening, always permitted.
    @discardableResult
    func block(_ raw: String) -> ExceptionResult {
        guard let domain = DomainInput.normalize(raw) else { return .invalidDomain }
        blockedDomains.insert(domain)
        allowedDomains.remove(domain)
        if enabled { apply() }
        save()
        return .ok
    }

    /// Stop blocking an extra site — weakening, so a commitment refuses it.
    @discardableResult
    func removeBlocked(_ domain: String) -> ExceptionResult {
        if isBound { return .locked }
        blockedDomains.remove(domain)
        if enabled { apply() }
        save()
        return .ok
    }

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
        enabled = on
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
        enabled ? apply() : clear()
        save()
    }

    func apply() {
        // Without real authorization the store rejects writes, so skip it.
        if Self.fakeGuard { return }

        // Apple's adult-content filter. This is the blocker: it works at the OS
        // level, so it covers Chrome, Brave, Firefox and in-app browsers rather
        // than one Safari extension, there is no extension for a user to switch
        // off, and the list is curated instead of keyword-guessed — which is
        // what stops legitimate sites being caught. Everything below only
        // shields what the user explicitly picked; without this line the blocker
        // blocks nothing at all unless they enumerate every site by hand.
        store.webContent.blockedByFilter = .auto(
            Set(blockedDomains.map { WebDomain(domain: $0) }),
            except: Set(allowedDomains.map { WebDomain(domain: $0) })
        )

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
        store.webContent.blockedByFilter = nil
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
        defaults?.set(Array(allowedDomains), forKey: Self.allowedKey)
        defaults?.set(Array(blockedDomains), forKey: Self.blockedKey)
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
        allowedDomains = Set(defaults?.stringArray(forKey: Self.allowedKey) ?? [])
        blockedDomains = Set(defaults?.stringArray(forKey: Self.blockedKey) ?? [])
        if let data = defaults?.data(forKey: Self.committedSelectionKey),
           let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            committedSelection = saved
        }
    }
}
