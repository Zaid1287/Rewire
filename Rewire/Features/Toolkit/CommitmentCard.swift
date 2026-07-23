import SwiftUI

/// The commitment-lock card in each of its states. A pure function of
/// `state` + callbacks, so every state is previewable and reviewable without
/// Screen Time authorization — which the Simulator can't grant without a
/// device passcode, making the states otherwise unreachable off-device.
struct CommitmentCard: View {
    var state: CommitmentLock.State
    /// Ticked by the caller so countdowns move.
    var now: Date
    var onCommit: () -> Void
    var onRequestUnlock: () -> Void
    var onCancelRequest: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            switch state {
            case .off:                     offer
            case .locked(let until):       locked(until)
            case .cooling(let readyAt):    cooling(readyAt)
            case .unlockable(let until):   unlockable(until)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
    }

    // MARK: States

    private var offer: some View {
        Group {
            header("lock.shield", "Lock it in", tint: Theme.Colors.textPrimary)
            body("Decide now, while it's easy. Once locked, switching the blocker off takes a \(minutes(CommitmentLock.coolingOff))-minute wait — long enough for an urge to pass.")
            filled("Set a commitment", action: onCommit)
        }
    }

    private func locked(_ until: Date) -> some View {
        Group {
            header("lock.fill", "Locked in", tint: Theme.Colors.butter)
            body("You committed until \(until.formatted(date: .abbreviated, time: .shortened)). Until then the blocker stays on and can only be made stronger.")
            quiet("I need to turn it off", action: onRequestUnlock)
            // Never claim more than the lock can do — this review cluster is
            // full of people burned by blockers that promised to be unbreakable.
            Text("This raises the cost of a weak moment. It can't stop you turning off Screen Time in iOS Settings.")
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Colors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func cooling(_ readyAt: Date) -> some View {
        Group {
            header("hourglass", "Unlocks in \(countdown(to: readyAt))", tint: Theme.Colors.butter)
            body("The wait is the point — most urges pass well inside it. If this one does, keep your streak and stay locked.")
            filled("I'm good — keep me locked", action: onCancelRequest)
        }
    }

    private func unlockable(_ until: Date) -> some View {
        Group {
            header("lock.open.fill", "Unlocked for \(countdown(to: until))", tint: Theme.Colors.textSecondary)
            body("You can switch the blocker off now. Do nothing and the commitment holds.")
            filled("Changed my mind — stay locked", action: onCancelRequest)
        }
    }

    // MARK: Pieces

    private func header(_ symbol: String, _ title: String, tint: Color) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: symbol)
            Text(title).font(Theme.Typography.headline())
        }
        .foregroundStyle(tint)
    }

    private func body(_ text: String) -> some View {
        Text(text)
            .font(Theme.Typography.subtitle())
            .foregroundStyle(Theme.Colors.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func filled(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Typography.button())
                .foregroundStyle(Color(hex: 0x141416))
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Theme.Colors.butter, in: Capsule())
        }
        .buttonStyle(PressableButtonStyle())
        .padding(.top, Theme.Spacing.xs)
    }

    private func quiet(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Typography.button())
                .foregroundStyle(Theme.Colors.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Theme.Colors.surface2, in: Capsule())
        }
        .buttonStyle(PressableButtonStyle())
    }

    private func minutes(_ t: TimeInterval) -> Int { Int(t / 60) }

    private func countdown(to date: Date) -> String {
        let s = max(0, Int(date.timeIntervalSince(now)))
        return s >= 60 ? "\(s / 60)m \(s % 60)s" : "\(s)s"
    }
}

#Preview {
    let now = Date()
    return ScrollView {
        VStack(spacing: 16) {
            ForEach(Array([
                CommitmentLock.State.off,
                .locked(until: now.addingTimeInterval(7 * 86_400)),
                .cooling(readyAt: now.addingTimeInterval(1_784)),
                .unlockable(until: now.addingTimeInterval(540))
            ].enumerated()), id: \.offset) { _, state in
                CommitmentCard(state: state, now: now,
                               onCommit: {}, onRequestUnlock: {}, onCancelRequest: {})
            }
        }
        .screenPadding()
    }
    .background { SceneBackground(kind: .void) }
}
