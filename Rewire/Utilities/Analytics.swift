import Foundation
import PostHog

/// Thin analytics facade — the only place PostHog is touched, so what we
/// send stays auditable in one file.
///
/// Privacy rule for this app: events are funnel / feature-usage ONLY.
/// Never capture content — no quiz answers, no report P/M/O flags, no
/// relapse reasons, no motivation text, no photos, no personal data.
enum Analytics {
    /// Empty until the PostHog project exists — leave "" to ship with
    /// analytics disabled. Set the real key (and EU host if applicable)
    /// once the org account is ready.
    private static let apiKey = ""
    private static let host = "https://us.i.posthog.com"

    private(set) static var enabled = false

    /// Call once at launch. No-op while `apiKey` is empty.
    static func start() {
        guard !apiKey.isEmpty else { return }
        let config = PostHogConfig(projectToken: apiKey, host: host)
        PostHogSDK.shared.setup(config)
        enabled = true
    }

    static func capture(_ event: String, _ properties: [String: Any]? = nil) {
        guard enabled else { return }
        PostHogSDK.shared.capture(event, properties: properties)
    }
}
