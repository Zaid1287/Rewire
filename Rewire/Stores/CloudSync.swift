import CloudKit
import Foundation

/// Private iCloud backup + cross-device sync (backend plan, stage B1).
///
/// **Why CloudKit and not our own server.** Everything in `AppSnapshot` is
/// special-category health data — slip reasons, P/M/O flags, motivations. The
/// private CloudKit database stores it in *the user's own iCloud*, encrypted by
/// Apple, on infrastructure we do not operate and cannot read. That is the only
/// shape of "not local-only" that doesn't turn us into the thing this app's
/// users are afraid of. Nothing here ever touches a Rewire-operated server; the
/// social half of the plan (Supabase, buddies) is a separate stage and only
/// ever carries a streak *count*, never this payload.
///
/// **Opt-in, default off.** Data still leaves the device, even if only to the
/// user's own iCloud, so it is the user's call — same contract as analytics.
///
/// **Not wired up yet.** `containerID` is nil until the iCloud capability and
/// the container exist in the developer portal; every entry point below is a
/// no-op that reports `.unavailable` until then. See HANDOFF.md for the manual
/// steps — and the privacy copy still promising "no cloud" must be rewritten in
/// the same change that sets this, per the backend plan.
@MainActor @Observable
final class CloudSync {

    /// Set to `"iCloud.com.manimacha.rewire"` once the capability is enabled
    /// and the container is registered. Touching `CKContainer` without a
    /// provisioned container raises, so every path checks this first.
    static let containerID: String? = nil

    enum Status: Equatable {
        /// No iCloud capability compiled in yet.
        case unavailable
        /// Capability present, user hasn't turned sync on.
        case off
        /// On, but iCloud itself isn't usable (signed out, restricted).
        case noAccount
        case syncing
        case synced(Date)
        case failed(String)
    }

    private(set) var status: Status = containerID == nil ? .unavailable : .off

    private var container: CKContainer? {
        Self.containerID.map { CKContainer(identifier: $0) }
    }

    private static let recordType = "AppSnapshot"
    private static let recordName = "state"
    private static let payloadKey = "payload"

    /// Called on launch and on foreground. No-ops unless the user opted in.
    func syncIfEnabled(optedIn: Bool) async {
        guard let container else { status = .unavailable; return }
        guard optedIn else { status = .off; return }

        do {
            let account = try await container.accountStatus()
            guard account == .available else { status = .noAccount; return }
        } catch {
            status = .failed(error.localizedDescription)
            return
        }

        status = .syncing
        do {
            let local = PersistenceController.shared.currentSnapshot()
            let remote = try await fetchRemote(container)
            if let merged = Self.merge(local: local, remote: remote) {
                // Apply first so the device reflects anything the other one
                // recorded, then push the combined result back.
                if remote != nil { PersistenceController.shared.restoreAll(from: merged) }
                try await push(merged, to: container)
            }
            status = .synced(Date())
        } catch {
            status = .failed(error.localizedDescription)
        }
    }

    /// Turning sync off leaves the iCloud copy in place — it's the user's own
    /// backup in their own account, and silently deleting it would be the
    /// surprise. `deleteCloudCopy()` is the explicit way to remove it.
    func deleteCloudCopy() async {
        guard let container else { return }
        let db = container.privateCloudDatabase
        let id = CKRecord.ID(recordName: Self.recordName)
        do {
            try await db.deleteRecord(withID: id)
            status = .off
        } catch {
            status = .failed(error.localizedDescription)
        }
    }

    // MARK: CloudKit I/O

    private func fetchRemote(_ container: CKContainer) async throws -> AppSnapshot? {
        let id = CKRecord.ID(recordName: Self.recordName)
        do {
            let record = try await container.privateCloudDatabase.record(for: id)
            guard let data = record[Self.payloadKey] as? Data else { return nil }
            return try JSONDecoder().decode(AppSnapshot.self, from: data)
        } catch let error as CKError where error.code == .unknownItem {
            return nil   // first sync on this account
        }
    }

    private func push(_ snapshot: AppSnapshot, to container: CKContainer) async throws {
        let id = CKRecord.ID(recordName: Self.recordName)
        let record = (try? await container.privateCloudDatabase.record(for: id))
            ?? CKRecord(recordType: Self.recordType, recordID: id)
        record[Self.payloadKey] = try JSONEncoder().encode(snapshot) as NSData
        _ = try await container.privateCloudDatabase.save(record)
    }

    // MARK: Merge — the part that decides whose data survives

    /// Combine two snapshots without losing anything a user actually recorded.
    ///
    /// Whole-snapshot last-write-wins would be one line, and would silently
    /// destroy real history: log a slip on the phone in airplane mode, check in
    /// on the iPad, and whichever synced second erases the other. So:
    ///
    /// - **History is append-only and unioned by id** — reports, streaks,
    ///   events, motivations, photos. A record written anywhere survives.
    /// - **Progress sets are unioned** — badges, achievements, plan days. You
    ///   never un-earn something by syncing.
    /// - **`recordSeconds` takes the max** — a personal best is a high-water
    ///   mark, never something a stale device can lower.
    /// - **Everything else follows the newer `updatedAt`** — current streak
    ///   start, goal, settings. `nil` sorts oldest, so a pre-sync snapshot
    ///   never overwrites one that knew about sync.
    /// - **Premium is not merged at all** — StoreKit entitlement is the source
    ///   of truth and re-asserts itself on launch.
    static func merge(local: AppSnapshot?, remote: AppSnapshot?) -> AppSnapshot? {
        guard let local else { return remote }
        guard let remote else { return local }

        let localIsNewer = (local.updatedAt ?? .distantPast) >= (remote.updatedAt ?? .distantPast)
        var merged = localIsNewer ? local : remote      // scalars from the newer side

        merged.reports = unionByID(local.reports, remote.reports, \.id)
        merged.streaks = unionByID(local.streaks, remote.streaks, \.id)
        merged.events = unionByID(local.events, remote.events, \.id)
        merged.motivations = unionByID(local.motivations ?? [], remote.motivations ?? [], \.id)
        merged.appearancePhotos = unionByID(local.appearancePhotos ?? [],
                                            remote.appearancePhotos ?? [], \.id)

        merged.claimedBadges = local.claimedBadges.union(remote.claimedBadges)
        merged.achievements = (local.achievements ?? []).union(remote.achievements ?? [])
        merged.completedPlanDays = (local.completedPlanDays ?? [])
            .union(remote.completedPlanDays ?? [])
        merged.hasEverJoinedChallenge =
            (local.hasEverJoinedChallenge ?? false) || (remote.hasEverJoinedChallenge ?? false)

        merged.recordSeconds = max(local.recordSeconds, remote.recordSeconds)

        // Entitlement, not synced state.
        merged.isPremium = local.isPremium
        merged.premiumPlan = local.premiumPlan

        merged.updatedAt = Date()
        return merged
    }

    /// Union preserving the first occurrence of each id, local first so a
    /// locally-edited copy wins over a stale remote one with the same id.
    private static func unionByID<T, ID: Hashable>(_ a: [T], _ b: [T],
                                                   _ id: KeyPath<T, ID>) -> [T] {
        var seen = Set<ID>()
        return (a + b).filter { seen.insert($0[keyPath: id]).inserted }
    }

    #if DEBUG
    /// No test target, and this function decides which of a user's recorded
    /// slips survives a sync — so it checks itself on debug launch.
    static func selfCheck() {
        precondition(merge(local: nil, remote: nil) == nil)

        var old = AppSnapshot.selfCheckFixture
        old.updatedAt = Date(timeIntervalSince1970: 1_000)
        old.events = [StreakEvent(id: UUID(uuidString: "00000000-0000-0000-0000-0000000000AA")!,
                                  type: .relapse)]
        old.recordSeconds = 9_000
        old.claimedBadges = ["Determined"]

        var new = AppSnapshot.selfCheckFixture
        new.updatedAt = Date(timeIntervalSince1970: 2_000)
        new.events = [StreakEvent(id: UUID(uuidString: "00000000-0000-0000-0000-0000000000BB")!,
                                  type: .relapse)]
        new.recordSeconds = 10
        new.claimedBadges = ["Panic Breaker"]
        new.goal = Goal(label: "newer", seconds: 42)

        guard let m = merge(local: new, remote: old) else { preconditionFailure("merge lost both") }
        precondition(m.events.count == 2, "a slip logged on either device must survive a sync")
        precondition(m.claimedBadges == ["Determined", "Panic Breaker"],
                     "badges are never un-earned by syncing")
        precondition(m.recordSeconds == 9_000, "a personal best must never be lowered by a merge")
        precondition(m.goal.label == "newer", "scalars follow the newer snapshot")

        // Order must not matter for the append-only parts.
        guard let flipped = merge(local: old, remote: new) else { preconditionFailure("merge lost both") }
        precondition(flipped.events.count == 2)
        precondition(flipped.recordSeconds == 9_000)

        // A snapshot written before sync existed (nil updatedAt) must not win.
        var ancient = AppSnapshot.selfCheckFixture
        ancient.updatedAt = nil
        ancient.goal = Goal(label: "ancient", seconds: 1)
        precondition(merge(local: new, remote: ancient)?.goal.label == "newer",
                     "a pre-sync snapshot must never overwrite a newer one")
        print("CloudSync.selfCheck passed")
    }
    #endif
}
