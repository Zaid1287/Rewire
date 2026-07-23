import Foundation

/// Self-binding for the porn blocker — the "Accountability / Self-Discipline"
/// review cluster's loudest request: *"It is tempting for me to go back in and
/// delete or toggle off blocker status"*, *"it could be stricter… real
/// accountability would make the streaks actually meaningful"*.
///
/// The binding is a **time delay, not a password**. Face ID proves you are the
/// device owner, which is precisely the person trying to bypass it at 1am — so
/// biometrics alone are a speed bump. What defeats an urge is outlasting it,
/// and Rewire's own panic copy says most urges are done by minute 10–15. So
/// turning the blocker off mid-commitment costs a wait, and the wait is the
/// whole feature.
///
/// Honesty about the ceiling: iOS lets anyone revoke Screen Time in Settings or
/// delete the app, and nothing here can stop that. This raises the cost of a
/// weak moment; it does not imprison anyone, and the UI must never claim it does.
struct CommitmentLock: Equatable, Codable {
    /// End of the commitment the user chose while motivated.
    var lockedUntil: Date?
    /// When the user asked to get out early — starts the cooling-off wait.
    var unlockRequestedAt: Date?

    /// How long an early-exit request has to sit before it's honoured. Longer
    /// than the 10–15 minute urge peak, short enough that a genuine need (the
    /// reviewer locked out of a government website) isn't a hostage situation.
    static let coolingOff: TimeInterval = 30 * 60

    /// How long the unlock stays available once the wait is served. Without
    /// this, a request made calmly in the morning would leave the blocker
    /// permanently one tap from off all evening — pre-arming the escape hatch
    /// is exactly the bypass this feature exists to close.
    static let unlockWindow: TimeInterval = 10 * 60

    enum State: Equatable {
        /// No commitment running — the blocker toggles freely.
        case off
        /// Bound until this date. Weakening the blocker is refused.
        case locked(until: Date)
        /// Early exit requested; honoured at this date.
        case cooling(readyAt: Date)
        /// Wait served — the user may now turn the blocker off, until `until`.
        case unlockable(until: Date)
    }

    func state(now: Date = Date()) -> State {
        guard let lockedUntil, now < lockedUntil else { return .off }
        guard let requested = unlockRequestedAt else { return .locked(until: lockedUntil) }

        let readyAt = requested + Self.coolingOff
        if now < readyAt { return .cooling(readyAt: readyAt) }

        let closesAt = readyAt + Self.unlockWindow
        // Request lapsed unused — back to bound, and they must wait again.
        return now < closesAt ? .unlockable(until: closesAt) : .locked(until: lockedUntil)
    }

    /// True while the blocker may not be switched off or narrowed.
    func binds(now: Date = Date()) -> Bool {
        switch state(now: now) {
        case .off, .unlockable: false
        case .locked, .cooling: true
        }
    }

    // MARK: Transitions

    mutating func commit(for duration: TimeInterval, now: Date = Date()) {
        lockedUntil = now + duration
        unlockRequestedAt = nil
    }

    /// Start the cooling-off wait. No-op if one is already running, so tapping
    /// twice can't restart (or shorten) the clock.
    mutating func requestUnlock(now: Date = Date()) {
        guard case .locked = state(now: now) else { return }
        unlockRequestedAt = now
    }

    /// Abandon an early-exit request — the "I'm good, keep me locked" path.
    mutating func cancelUnlockRequest() { unlockRequestedAt = nil }

    mutating func release() {
        lockedUntil = nil
        unlockRequestedAt = nil
    }

    /// Durations offered at setup. Mirrors the reviewer's own list —
    /// *"a designated amount of days set by the user (ex. 1 week, 2 weeks, 1 month)"*.
    static let options: [(label: String, duration: TimeInterval)] = [
        ("1 day",    86_400),
        ("3 days",   3 * 86_400),
        ("1 week",   7 * 86_400),
        ("2 weeks",  14 * 86_400),
        ("1 month",  30 * 86_400)
    ]
}

#if DEBUG
extension CommitmentLock {
    /// The state machine is all edges and clocks, and the project has no test
    /// target — so it checks itself. Every transition below is one a user can
    /// actually walk into.
    static func selfCheck() {
        let t0 = Date(timeIntervalSince1970: 1_000_000)
        let week: TimeInterval = 7 * 86_400

        // Nothing committed → free.
        var l = CommitmentLock()
        precondition(l.state(now: t0) == .off)
        precondition(!l.binds(now: t0))

        // Committed → bound, and staying bound as time passes.
        l.commit(for: week, now: t0)
        precondition(l.binds(now: t0))
        precondition(l.binds(now: t0 + 3 * 86_400))
        guard case .locked = l.state(now: t0) else { preconditionFailure("expected locked") }

        // Commitment served → free again (the blocker stays on, it just stops binding).
        precondition(l.state(now: t0 + week + 1) == .off)

        // Early exit: still bound through the whole cooling-off wait.
        l.requestUnlock(now: t0 + 86_400)
        let requested = t0 + 86_400
        guard case .cooling(let readyAt) = l.state(now: requested + 60) else {
            preconditionFailure("expected cooling")
        }
        precondition(readyAt == requested + coolingOff)
        precondition(l.binds(now: requested + coolingOff - 1), "must bind right up to the deadline")

        // Wait served → a bounded window where it actually opens.
        guard case .unlockable = l.state(now: requested + coolingOff + 1) else {
            preconditionFailure("expected unlockable")
        }
        precondition(!l.binds(now: requested + coolingOff + 1))

        // Window lapses unused → bound again. This is the anti-pre-arm rule.
        precondition(l.binds(now: requested + coolingOff + unlockWindow + 1),
                     "a lapsed request must re-bind, or the escape hatch can be pre-armed")
        guard case .locked = l.state(now: requested + coolingOff + unlockWindow + 1) else {
            preconditionFailure("expected re-locked after lapse")
        }

        // Tapping request again mid-wait must not restart or shorten the clock.
        var l2 = CommitmentLock()
        l2.commit(for: week, now: t0)
        l2.requestUnlock(now: t0 + 100)
        l2.requestUnlock(now: t0 + 200)
        precondition(l2.unlockRequestedAt == t0 + 100, "second request must not move the clock")

        // Cancelling puts them straight back to bound, no partial credit.
        l2.cancelUnlockRequest()
        guard case .locked = l2.state(now: t0 + 300) else { preconditionFailure("expected locked") }
        precondition(l2.binds(now: t0 + 300))

        // Requesting is meaningless once the window is already open or expired.
        var l3 = CommitmentLock()
        l3.commit(for: week, now: t0)
        l3.requestUnlock(now: t0)
        l3.requestUnlock(now: t0 + coolingOff + 60)   // now unlockable, not locked
        precondition(l3.unlockRequestedAt == t0, "must not re-arm from the unlockable state")

        precondition(release(l3).state(now: t0) == .off)
        print("CommitmentLock.selfCheck passed")
    }

    private static func release(_ l: CommitmentLock) -> CommitmentLock {
        var c = l; c.release(); return c
    }
}
#endif
