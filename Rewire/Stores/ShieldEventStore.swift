import Foundation

/// One shield-button tap, written by the ShieldAction extension and drained by
/// the app on foreground. Deliberately dumb: the extension is memory-limited and
/// short-lived, so it appends a record and returns — all interpretation (streak
/// resets, patterns, undo bookkeeping) happens app-side in `StreakStore`.
struct ShieldEvent: Codable {
    /// "I relapsed" / "Not this time". Mirrors `StreakEvent.Kind`'s two shield
    /// cases but stays separate — this is a wire format between processes.
    enum Kind: String, Codable { case relapse, resisted }
    var id = UUID()
    var date = Date()
    var kind: Kind
}

/// The App Group channel between the shield extensions and the app.
///
/// ponytail: UserDefaults, not a file + NSFileCoordinator. The payload is a
/// handful of tiny records and the only writer is a shield tap, so the ceremony
/// buys nothing. Move to a coordinated file if events ever arrive fast enough to
/// race the app's drain.
enum ShieldEventStore {
    static let appGroup = "group.com.manimacha.rewire"

    private static let queueKey = "shield.events"
    private static let reshieldKey = "shield.pendingReshield"

    private static var defaults: UserDefaults? { UserDefaults(suiteName: appGroup) }

    /// Append a tap. Called from the extension — keep it this cheap.
    static func append(_ event: ShieldEvent) {
        write(pending() + [event])
    }

    static func pending() -> [ShieldEvent] {
        guard let data = defaults?.data(forKey: queueKey),
              let events = try? JSONDecoder().decode([ShieldEvent].self, from: data)
        else { return [] }
        return events
    }

    static func clear() { write([]) }

    /// Set by the extension when "I relapsed" unshields an app, so the app
    /// re-applies shields on next foreground. Phase S3 replaces this with a
    /// timed DeviceActivity interval that doesn't need Rewire to be opened.
    static var pendingReshield: Bool {
        get { defaults?.bool(forKey: reshieldKey) ?? false }
        set { defaults?.set(newValue, forKey: reshieldKey) }
    }

    private static func write(_ events: [ShieldEvent]) {
        guard let data = try? JSONEncoder().encode(events) else { return }
        defaults?.set(data, forKey: queueKey)
    }
}
