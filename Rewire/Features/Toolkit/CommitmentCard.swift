import SwiftUI

/// The commitment-lock card in each of its states. A pure function of
/// `state` + callbacks, so every state is previewable and reviewable without
/// Screen Time authorization — which the Simulator can't grant without a
/// device passcode, making the states otherwise unreachable off-device.
///
/// RonLab Family A: this sits on the Void scene, so the card is smoked glass,
/// never an opaque fill. The cooling-off wait is the hero moment and gets the
/// instrument treatment — a radial tick dial draining to a Thin hero numeral —
/// because a countdown is data, and data is an instrument here, not a text row.
/// Butter is reserved for that instrument and the single active element; the
/// primary action stays the white capsule.
struct CommitmentCard: View {
    var state: CommitmentLock.State
    /// Ticked by the caller so countdowns move.
    var now: Date
    var onCommit: () -> Void
    var onRequestUnlock: () -> Void
    var onCancelRequest: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            switch state {
            case .off:                     offer
            case .locked(let until):       locked(until)
            case .cooling(let readyAt):    cooling(readyAt)
            case .unlockable(let until):   unlockable(until)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .smokedGlass(radius: 32)
    }

    // MARK: States

    private var offer: some View {
        Group {
            eyebrow("Commitment")
            title("Lock it in")
            body("Decide now, while it's easy. Once locked, switching the blocker off costs a wait — long enough for an urge to pass.")
            labelValue("Cost to exit", "\(minutes(CommitmentLock.coolingOff)) min wait")
            PrimaryButton(title: "Set a commitment", action: onCommit)
        }
    }

    private func locked(_ until: Date) -> some View {
        Group {
            eyebrow("Locked in")
            // Hero stat: how much of the commitment is left. The number is the
            // point, so it's the biggest thing on the card.
            HeroNumeral(value: "\(daysLeft(until))",
                        unit: daysLeft(until) == 1 ? "day left" : "days left",
                        size: 76)
            labelValue("Until", until.formatted(date: .abbreviated, time: .shortened))
            labelValue("Blocker", "on · can only be strengthened")

            ghost("I need to turn it off", action: onRequestUnlock)

            // Never claim more than the lock can do — this review cluster is
            // full of people burned by blockers that promised to be unbreakable.
            caption("It can't stop you turning off Screen Time in iOS Settings.")
        }
    }

    private func cooling(_ readyAt: Date) -> some View {
        Group {
            eyebrow("Cooling off")

            // The instrument. Lit ticks are time REMAINING, so the ring starts
            // full and drains — lighting the served portion instead reads as an
            // empty, broken dial in the first minutes, which is exactly when
            // the user is looking at it.
            let remaining = max(0, readyAt.timeIntervalSince(now))
            ZStack {
                TickRing(count: 64,
                         activeFraction: remaining / CommitmentLock.coolingOff,
                         inactiveColor: .white.opacity(0.18),
                         activeColor: Theme.Colors.butter)
                    .frame(width: 208, height: 208)
                HeroNumeral(value: "\(Int(remaining) / 60)",
                            unit: String(format: "m %02ds", Int(remaining) % 60),
                            size: 72)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.xs)

            body("The wait is the point — most urges pass well inside it. If this one does, keep your streak and stay locked.")
            PrimaryButton(title: "I'm good — keep me locked", action: onCancelRequest)
        }
    }

    private func unlockable(_ until: Date) -> some View {
        Group {
            eyebrow("Unlocked")
            StatusLabel(color: Theme.Colors.critical, text: "Blocker can be switched off")
            HeroNumeral(value: "\(Int(max(0, until.timeIntervalSince(now))) / 60)",
                        unit: String(format: "m %02ds left",
                                     Int(max(0, until.timeIntervalSince(now))) % 60),
                        size: 72)
            body("Do nothing and the commitment holds.")
            PrimaryButton(title: "Changed my mind — stay locked", action: onCancelRequest)
        }
    }

    // MARK: Kit

    private func eyebrow(_ text: String) -> some View {
        Text(text.uppercased())
            .font(Theme.Typography.caption())
            .tracking(1.4)
            .foregroundStyle(Theme.Colors.textXlo)
    }

    /// Family A allows no bold — hierarchy is size and opacity only.
    private func title(_ text: String) -> some View {
        Text(text)
            .font(Theme.Typography.cardTitle())
            .foregroundStyle(Theme.Colors.textHi)
    }

    private func body(_ text: String) -> some View {
        Text(text)
            .font(Theme.Typography.label())
            .foregroundStyle(Theme.Colors.textLo)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func caption(_ text: String) -> some View {
        Text(text)
            .font(Theme.Typography.caption())
            .foregroundStyle(Theme.Colors.textXlo)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func labelValue(_ label: String, _ value: String) -> some View {
        HStack(spacing: 6) {
            Text("\(label):").foregroundStyle(Theme.Colors.textLo)
            Text(value).foregroundStyle(Theme.Colors.textHi)
            Spacer(minLength: 0)
        }
        .font(Theme.Typography.label())
        .monospacedDigit()
    }

    private func ghost(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Typography.button())
                .foregroundStyle(Theme.Colors.textHi)
                .frame(maxWidth: .infinity)
                .frame(height: 62)
                .background {
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
                }
        }
        .buttonStyle(PressableButtonStyle())
    }

    private func minutes(_ t: TimeInterval) -> Int { Int(t / 60) }

    /// Round up: with 6h left you have "1 day", not "0 days".
    private func daysLeft(_ until: Date) -> Int {
        max(1, Int(ceil(until.timeIntervalSince(now) / 86_400)))
    }
}

#Preview {
    let now = Date()
    return ScrollView {
        VStack(spacing: 14) {
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
