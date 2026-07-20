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

    // ponytail: the default store. Named stores only matter once schedules need
    // to shield different sets at different times — that's S3's problem.
    private let store = ManagedSettingsStore()

    private static let selectionKey = "guard.selection"
    private static let enabledKey = "guard.enabled"

    init() { load() }

    var isAuthorized: Bool { auth == .approved }

    /// Reflects the real state — a user can revoke Screen Time in Settings at
    /// any time, so trusting a stored flag would strand us shielding nothing.
    func refreshAuth() {
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
        !selection.applicationTokens.isEmpty
            || !selection.categoryTokens.isEmpty
            || !selection.webDomainTokens.isEmpty
    }

    func setEnabled(_ on: Bool) {
        enabled = on && hasSelection
        enabled ? apply() : clear()
        save()
    }

    /// Re-apply after a selection change, but only while the guard is on.
    func selectionChanged() {
        if enabled && !hasSelection { enabled = false }
        enabled ? apply() : clear()
        save()
    }

    func apply() {
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
    }

    private func load() {
        let defaults = UserDefaults(suiteName: ShieldEventStore.appGroup)
        enabled = defaults?.bool(forKey: Self.enabledKey) ?? false
        if let data = defaults?.data(forKey: Self.selectionKey),
           let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            selection = saved
        }
    }
}
