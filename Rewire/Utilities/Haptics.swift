import UIKit

/// Thin wrapper over UIFeedbackGenerator so views trigger haptics without
/// importing UIKit everywhere.
enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func select() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    // MARK: Breathing pacer (Panic urge tool)

    /// Held and pre-warmed: the breathing pacer fires up to 3 pulses a second
    /// and a generator built per pulse arrives late enough to smear the
    /// cadence. `.soft` carries the breath, `.rigid` marks a phase change.
    private static let breathSoft = UIImpactFeedbackGenerator(style: .soft)
    private static let breathMark = UIImpactFeedbackGenerator(style: .rigid)

    static func prepareBreathing() {
        breathSoft.prepare()
        breathMark.prepare()
    }

    /// One pulse of the breath pacer. Intensity is the whole point — the
    /// inhale swells and the exhale releases, so the hand feels the shape of
    /// the breath rather than a metronome.
    static func breathPulse(intensity: Double) {
        breathSoft.impactOccurred(intensity: max(0.15, min(1, intensity)))
        breathSoft.prepare()
    }

    /// The instant a phase turns over — crisper than the pulses inside it, so
    /// "start breathing out" never has to be read off the screen.
    static func breathPhaseMark() {
        breathMark.impactOccurred(intensity: 0.85)
        breathMark.prepare()
    }
}
