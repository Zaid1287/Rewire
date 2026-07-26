import SwiftUI

/// RonLab switch. The system `Toggle` ships iOS system-green — a second accent
/// on screens that are supposed to carry exactly one, and a filled chrome
/// control where the language calls for neutral chrome. This is the house
/// version: ghost track when off, butter when on (a switch is the "single
/// active element" the accent is reserved for), with the accent bleeding as a
/// glow behind the capsule rather than only filling it.
///
/// Motion is the slow diffused spring from the design language, never bouncy.
struct GlassSwitch: View {
    @Binding var isOn: Bool
    var isEnabled = true

    private let trackWidth: CGFloat = 52
    private let trackHeight: CGFloat = 32
    private let knob: CGFloat = 26

    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(isOn ? Theme.Colors.butter : Color.white.opacity(0.08))
                .overlay(
                    Capsule().strokeBorder(
                        isOn ? Theme.Colors.butter.opacity(0.6) : Color.white.opacity(0.14),
                        lineWidth: 1)
                )
                // The accent bleeds past the control instead of stopping at its
                // edge — the glow is what makes it read as lit, not just filled.
                .background(
                    Capsule()
                        .fill(Theme.Colors.butter)
                        .blur(radius: 14)
                        .opacity(isOn ? 0.45 : 0)
                )

            Circle()
                .fill(isOn ? Theme.Colors.ink : Color.white.opacity(0.55))
                .frame(width: knob, height: knob)
                .padding(3)
        }
        .frame(width: trackWidth, height: trackHeight)
        .opacity(isEnabled ? 1 : 0.35)
        .contentShape(Capsule())
        .onTapGesture {
            guard isEnabled else { return }
            Haptics.tap()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.88)) { isOn.toggle() }
        }
        .accessibilityRepresentation {
            Toggle("", isOn: $isOn).disabled(!isEnabled)
        }
    }
}

#Preview {
    @Previewable @State var a = true
    @Previewable @State var b = false
    return VStack(spacing: 24) {
        GlassSwitch(isOn: $a)
        GlassSwitch(isOn: $b)
        GlassSwitch(isOn: .constant(false), isEnabled: false)
    }
    .padding(40)
    .background { SceneBackground(kind: .void) }
}
