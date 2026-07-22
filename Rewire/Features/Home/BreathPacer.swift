import Foundation

/// 5-2-4 breathing: inhale 5, hold 2, exhale 4. The phases are deliberately
/// unequal — a longer exhale than inhale is what down-regulates arousal, and
/// the short hold is a hinge, not a test of breath control.
enum BreathPhase: Int, CaseIterable {
    case breatheIn, hold, breatheOut

    var seconds: Int {
        switch self {
        case .breatheIn:  5
        case .hold:       2
        case .breatheOut: 4
        }
    }
    var label: String {
        switch self {
        case .breatheIn:  "Breathe in"
        case .hold:       "Hold"
        case .breatheOut: "Breathe out"
        }
    }
    /// Lungs full while inhaling and holding; empty on the exhale.
    var lungsFull: Bool { self != .breatheOut }

    /// Haptic pulses per second — the Apple Watch Breathe idea: a slow pulse
    /// paces the inhale, a faster flutter drives the exhale out, and the hold
    /// is silent because stillness is the instruction.
    var pulsesPerSecond: Int {
        switch self {
        case .breatheIn:  1
        case .hold:       0
        case .breatheOut: 3
        }
    }

    /// Intensity ramp across the phase: the inhale swells toward full, the
    /// exhale empties out. Read at the phase's own progress (0→1).
    func intensity(at progress: Double) -> Double {
        switch self {
        case .breatheIn:  0.35 + 0.65 * progress
        case .hold:       0
        case .breatheOut: 0.75 - 0.50 * progress
        }
    }
}

/// The beat schedule behind the breath haptics. Pure logic, no SwiftUI, so the
/// cadence can be checked on its own — see `selfCheck()`.
enum BreathPacer {
    static let cycleSeconds = BreathPhase.allCases.reduce(0) { $0 + $1.seconds }

    /// Split a position in the cycle into its phase and how far into it we are.
    static func locate(_ positionInCycle: Double) -> (phase: BreathPhase, into: Double) {
        var t = positionInCycle
        for p in BreathPhase.allCases {
            if t < Double(p.seconds) { return (p, t) }
            t -= Double(p.seconds)
        }
        return (.breatheIn, 0)
    }

    /// What the driver last delivered, so a clock running faster than the beat
    /// still fires each beat exactly once.
    struct State: Equatable {
        var phaseKey = -1
        var pulseKey = -1
    }

    enum Beat: Equatable {
        case none
        /// Phase turn-over — one crisp mark. Stands in for pulse 0 so a mark
        /// and a pulse never stack into a double-hit.
        case mark
        case pulse(intensity: Double)
    }

    /// Advance the pacer to time `t` (seconds since the breath began).
    static func advance(_ state: inout State, at t: TimeInterval) -> Beat {
        let cycle = Int(t) / cycleSeconds
        let (phase, into) = locate(t.truncatingRemainder(dividingBy: Double(cycleSeconds)))

        let phaseKey = cycle * BreathPhase.allCases.count + phase.rawValue
        if phaseKey != state.phaseKey {
            state.phaseKey = phaseKey
            state.pulseKey = 0
            return .mark
        }

        let rate = phase.pulsesPerSecond
        guard rate > 0 else { return .none }          // hold is silent by design
        let pulse = min(Int(into * Double(rate)), phase.seconds * rate - 1)
        guard pulse != state.pulseKey else { return .none }
        state.pulseKey = pulse
        return .pulse(intensity: phase.intensity(at: into / Double(phase.seconds)))
    }
}

#if DEBUG
extension BreathPacer {
    /// Runs the real 6 Hz driver over two cycles and asserts the cadence. The
    /// failure this guards against is a clock faster than the beat either
    /// double-firing or dropping pulses.
    static func selfCheck() {
        precondition(cycleSeconds == 11, "5+2+4 should be an 11s cycle")

        // Phase boundaries.
        precondition(locate(0).phase == .breatheIn)
        precondition(locate(4.9).phase == .breatheIn)
        precondition(locate(5).phase == .hold)
        precondition(locate(6.9).phase == .hold)
        precondition(locate(7).phase == .breatheOut)
        precondition(locate(10.9).phase == .breatheOut)

        // Drive two full cycles at 6 Hz and tally what the hand would feel.
        var state = State()
        var marks = 0, pulses = 0
        var pulsesByPhase = [BreathPhase: Int]()
        let step = 1.0 / 6.0
        for i in 0..<Int((Double(cycleSeconds) * 2) / step) {
            let t = Double(i) * step
            let phase = locate(t.truncatingRemainder(dividingBy: Double(cycleSeconds))).phase
            switch advance(&state, at: t) {
            case .none: continue
            case .mark: marks += 1
            case .pulse(let intensity):
                pulses += 1
                pulsesByPhase[phase, default: 0] += 1
                precondition(intensity > 0 && intensity <= 1, "intensity out of range: \(intensity)")
            }
        }

        // 3 phases × 2 cycles, each turn-over marked exactly once.
        precondition(marks == 6, "expected 6 phase marks, got \(marks)")
        // Inhale: 5 beats at 1/s, minus the one the mark stands in for = 4.
        precondition(pulsesByPhase[.breatheIn] == 8, "inhale: \(pulsesByPhase[.breatheIn] ?? 0)")
        // Hold is silent.
        precondition(pulsesByPhase[.hold] == nil, "hold should be silent")
        // Exhale: 4s × 3/s = 12 beats, minus the one the mark stands in for = 11.
        precondition(pulsesByPhase[.breatheOut] == 22, "exhale: \(pulsesByPhase[.breatheOut] ?? 0)")
        precondition(pulses == 30, "expected 30 pulses over two cycles, got \(pulses)")

        // The inhale swells and the exhale releases.
        precondition(BreathPhase.breatheIn.intensity(at: 0) < BreathPhase.breatheIn.intensity(at: 1))
        precondition(BreathPhase.breatheOut.intensity(at: 0) > BreathPhase.breatheOut.intensity(at: 1))

        print("BreathPacer.selfCheck passed — \(marks) marks, \(pulses) pulses over 2 cycles")
    }
}
#endif
