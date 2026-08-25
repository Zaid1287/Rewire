import Foundation
import Supabase

/// Supabase client + the only place social data is read or written
/// (backend plan, stage B2 — accountability buddy).
///
/// **The line this file exists to hold.** `CloudSync` carries the whole
/// `AppSnapshot` — slip reasons, P/M/O flags, motivations, photos — into the
/// user's *own* iCloud, which we cannot read. This file talks to a
/// Rewire-operated Postgres, so it carries almost nothing: a pseudonymous
/// handle, a streak *count*, a check-in date, a pairing. That asymmetry is the
/// privacy promise. If a method here ever takes an `AppSnapshot`, a
/// `DailyReport`, a relapse reason, or an image, the promise is broken —
/// route it through `CloudSync` instead.
///
/// **Opt-in, default off**, same contract as `Analytics` and `CloudSync`:
/// nothing is sent until the user turns social on. Sync/backup does not need
/// this — it runs on iCloud identity alone, no login.
///
/// **Infra only right now.** Schema, RLS and this client exist
/// (`supabase/migrations/`, applied to project `keaxgmvjrcqwfqeskchs`, RLS proven by
/// `supabase/tests/rls_check.sql`); the pairing UI and Sign in with
/// Apple are separate cards. Nothing calls `enable()` yet, so the app's
/// behaviour is unchanged until they land — and per the backend plan, the
/// onboarding copy still promising "no cloud" must be rewritten in the same
/// change that ships the buddy feature to users.
@MainActor @Observable
final class SocialBackend {

    /// Project `keaxgmvjrcqwfqeskchs`. The publishable key is client-side by
    /// design — it carries no privileges of its own, RLS is what protects the
    /// data. The `service_role` key must never appear in this app, or in this
    /// repo: it bypasses every policy in the migration.
    private static let projectURL = URL(string: "https://keaxgmvjrcqwfqeskchs.supabase.co")!
    private static let publishableKey = "sb_publishable_NCLiQfKTGn6MKQscsKc9jg_LHe6j0-V"

    enum Status: Equatable {
        /// User hasn't turned social on.
        case off
        /// On, but nobody is signed in yet (Sign in with Apple — separate card).
        case signedOut
        case ready
        case failed(String)
    }

    private(set) var status: Status = .off

    /// Built lazily so an install that never turns social on never constructs
    /// a client or opens a connection.
    private var client: SupabaseClient?

    private func makeClient() -> SupabaseClient {
        if let client { return client }
        let client = SupabaseClient(supabaseURL: Self.projectURL, supabaseKey: Self.publishableKey)
        self.client = client
        return client
    }

    /// Call when the user turns social on, and at launch with the persisted flag.
    func enable(_ on: Bool) async {
        guard on else {
            // Sign out drops the local session; the row stays, so turning it
            // back on reconnects rather than starting over. Deleting the
            // account is an explicit, separate path.
            try? await client?.auth.signOut()
            status = .off
            return
        }
        status = (makeClient().auth.currentSession == nil) ? .signedOut : .ready
    }

    // MARK: - Buddy surface
    //
    // Every method below is deliberately narrow: a count and a date out, a
    // count and a date in. There is no general-purpose "sync" entry point,
    // because there is nothing else this database is allowed to hold.

    /// Publish the user's own streak count + last check-in for their buddy.
    func publish(streakDays: Int, lastCheckIn: Date?) async throws {
        guard case .ready = status, let client, let userID = client.auth.currentSession?.user.id else { return }
        try await client.from("shared_streak_state")
            .upsert(SharedStreakState(userID: userID,
                                      streakDays: streakDays,
                                      lastCheckIn: lastCheckIn.map(Self.dayFormatter.string(from:))))
            .execute()
    }

    /// Read the buddy's side. RLS returns nothing unless an accepted pair
    /// exists, so this is safe to call speculatively.
    func buddyState() async throws -> SharedStreakState? {
        guard case .ready = status, let client, let userID = client.auth.currentSession?.user.id else { return nil }
        let rows: [SharedStreakState] = try await client.from("shared_streak_state")
            .select()
            .neq("user_id", value: userID.uuidString)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    /// Create an invite. The code is a bearer token — single-use, burned by
    /// `redeem_buddy_invite` server-side.
    func createInvite() async throws -> String? {
        guard case .ready = status, let client, let userID = client.auth.currentSession?.user.id else { return nil }
        let code = Self.inviteCode()
        try await client.from("buddy_pairs")
            .insert(["requester_id": userID.uuidString, "invite_code": code])
            .execute()
        return code
    }

    /// Redeem a buddy's invite code. Goes through the RPC, not a table read:
    /// pending rows are unreadable on purpose so invite codes can't be enumerated.
    func redeemInvite(_ code: String) async throws {
        guard case .ready = status, let client else { return }
        try await client.rpc("redeem_buddy_invite", params: ["code": code]).execute()
    }

    /// Unambiguous alphabet — no O/0, no I/1/l — because people read these
    /// aloud and type them from a screenshot.
    static func inviteCode(length: Int = 8) -> String {
        let alphabet = Array("ABCDEFGHJKMNPQRSTUVWXYZ23456789")
        return String((0..<length).map { _ in alphabet.randomElement()! })
    }

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    #if DEBUG
    /// No test target; guards the invariants that matter, like
    /// `Analytics.selfCheck` and `CloudSync.selfCheck`.
    static func selfCheck() {
        precondition(!publishableKey.contains("service_role"),
                     "the service_role key must never ship in the client")
        precondition(publishableKey.hasPrefix("sb_publishable_"),
                     "only the publishable key belongs in the app")
        let code = inviteCode()
        precondition(code.count == 8)
        precondition(!code.contains(where: { "O0I1L".contains($0) }),
                     "invite alphabet must stay unambiguous")
        // The shared payload is a count and a date. Nothing else is encodable
        // into it, which is the point.
        let state = SharedStreakState(userID: UUID(), streakDays: 12, lastCheckIn: "2026-08-25")
        let encoded = try! JSONEncoder().encode(state)
        let keys = Set((try! JSONSerialization.jsonObject(with: encoded) as! [String: Any]).keys)
        precondition(keys.isSubset(of: ["user_id", "streak_days", "last_check_in"]),
                     "shared state must never gain a field")
        print("SocialBackend.selfCheck passed")
    }
    #endif
}

/// The complete set of fields Rewire's server is allowed to hold about a user's
/// recovery. Adding a case here is a privacy decision, not a schema tweak.
struct SharedStreakState: Codable, Equatable {
    let userID: UUID
    let streakDays: Int
    /// `yyyy-MM-dd`, UTC — a date, never a timestamp, so it can't be read as a
    /// behavioural log of when someone opens the app.
    let lastCheckIn: String?

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case streakDays = "streak_days"
        case lastCheckIn = "last_check_in"
    }
}
