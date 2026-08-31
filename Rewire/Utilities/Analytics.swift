import Foundation
import PostHog

/// Thin analytics facade — the only place PostHog is touched, so what we send
/// stays auditable in one file.
///
/// **Privacy rule for this app: events are funnel / feature-usage ONLY.**
/// Never capture content — no quiz answers, no report P/M/O flags, no relapse
/// reasons, no motivation text, no photos, no personal data. Given the data
/// class (special-category health data about porn addiction), that rule is
/// enforced in code here, not left to whoever writes the next `capture` call:
///
/// 1. **Opt-in, default off.** Nothing is sent until the user turns it on in
///    Settings. No "legitimate interest" reading of consent for this data.
/// 2. **Anonymous only.** `personProfiles = .never`, and we never call
///    `identify`, so there is no profile to join events onto.
/// 3. **No autocapture.** PostHog defaults to `captureScreenViews` +
///    `enableSwizzling`, which would ship screen names like "PanicSheet" and
///    "AppearanceTracker" without a line of our code. Both are off — if an
///    event isn't in this file, it isn't sent.
/// 4. **Property allowlist.** `capture` drops any key not on `allowedKeys`,
///    and a `beforeSend` block re-applies the same filter at the SDK boundary
///    so anything the SDK adds itself can't slip past either. (PostHog's own
///    `$` metadata — app version, OS, device model — is kept: it's not user
///    content, and it's what makes funnel numbers readable.)
enum Analytics {
    /// PostHog project 257570, EU cloud. This is a write-only *project* token
    /// (client-side by design, safe to ship); it is not a personal API key.
    /// Set back to "" to ship with analytics disabled regardless of consent.
    private static let apiKey = "phc_vQWV8qoYApzjPNoKwvgeqZgiGLb846JLRngkdu8iP34g"
    private static let host = "https://eu.i.posthog.com"

    /// The only property keys allowed to leave the device. Everything is a
    /// low-cardinality enum-ish string chosen by us — never user text.
    static let allowedKeys: Set<String> = ["plan", "step", "badge"]

    /// True only when a key is configured AND the user opted in.
    private(set) static var enabled = false

    /// Whether a key is compiled in at all — lets Settings hide the toggle
    /// rather than offer a switch that does nothing.
    static var isAvailable: Bool { !apiKey.isEmpty }

    /// Call once at launch with the persisted consent flag, and again whenever
    /// the user changes it.
    static func start(optedIn: Bool) {
        guard isAvailable else { enabled = false; return }

        // **Do not configure the SDK for someone who hasn't opted in.**
        // `setup()` is not inert: `captureApplicationLifecycleEvents` makes the
        // SDK queue an "Application Installed" event and flush it immediately,
        // which happened *before* the `optOut()` below could run. On a decline,
        // one event reached PostHog from a user who had just said no — proven
        // in the simulator by "Sending batch of 1 records / batch sent
        // successfully" on the decline path. Not user content, but it breaks
        // the promise the toggle makes and the App Store privacy answer with
        // it. Nothing may touch the network before consent, so an un-consented
        // user never reaches `setup()` at all.
        guard optedIn else {
            // Only meaningful if consent was granted earlier in this install
            // and is now being withdrawn; otherwise there is nothing to stop.
            if configured {
                PostHogSDK.shared.optOut()
                // Drop the anonymous id and any queued events, so turning it
                // off isn't just "stop sending from now on".
                PostHogSDK.shared.reset()
            }
            enabled = false
            return
        }

        if !configured {
            let config = PostHogConfig(projectToken: apiKey, host: host)
            // Anonymous forever: no identify() anywhere in the app, and no
            // person profile for events to accumulate against.
            config.personProfiles = .never
            config.setDefaultPersonProperties = false
            // No autocapture. See rule 3 above.
            config.captureScreenViews = false
            config.enableSwizzling = false
            config.captureApplicationLifecycleEvents = true   // opens/installs only, no content
            config.sessionReplay = false
            // Same allowlist re-applied where the SDK builds the final
            // payload, so anything the SDK adds is filtered too.
            config.setBeforeSend { event in
                event.properties = event.properties.filter {
                    $0.key.hasPrefix("$") || allowedKeys.contains($0.key)
                }
                return event
            }
            #if DEBUG
            // REWIRE_PH_DEBUG=1 makes the SDK log every event it accepts.
            // Without it, "nothing was captured" and "captured then flushed"
            // both look like an empty queue on disk, so there is no way to
            // tell a working funnel from a silent one. Debug builds only.
            if ProcessInfo.processInfo.environment["REWIRE_PH_DEBUG"] == "1" {
                config.debug = true
            }
            #endif
            PostHogSDK.shared.setup(config)
            configured = true
        }

        PostHogSDK.shared.optIn()
        enabled = true
    }

    private static var configured = false

    static func capture(_ event: String, _ properties: [String: Any]? = nil) {
        guard enabled else { return }
        PostHogSDK.shared.capture(event, properties: properties.map(sanitize))
    }

    /// Drop anything not explicitly allowed, and stringify what survives so a
    /// caller can't smuggle a rich object through.
    static func sanitize(_ properties: [String: Any]) -> [String: Any] {
        properties
            .filter { allowedKeys.contains($0.key) }
            .mapValues { String(describing: $0) }
    }

    #if DEBUG
    /// No test target; this guards the one rule that matters, so it checks
    /// itself on debug launch (same pattern as `StreakStore.selfCheck`).
    static func selfCheck() {
        let dirty: [String: Any] = [
            "plan": "com.manimacha.rewire.premium.yearly",
            "note": "I relapsed because I was lonely",   // the thing that must never leave
            "trigger": "Loneliness",
            "watchedPorn": true,
            "step": "welcome"
        ]
        let clean = sanitize(dirty)
        precondition(Set(clean.keys) == ["plan", "step"],
                     "only allowlisted keys may be captured")
        precondition(!clean.values.contains { ($0 as? String)?.contains("lonely") == true },
                     "slip-log content must never reach analytics")
        precondition(sanitize([:]).isEmpty)
        print("Analytics.selfCheck passed")
    }
    #endif
}
