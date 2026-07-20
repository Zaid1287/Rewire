import SwiftUI

/// Opaque carbon capsule with the `Label: Value` pattern and a chevron —
/// the RonLab dropdown/selector row ("Goal: 90 days clean ⌄").
struct PillRow: View {
    var label: String
    var value: String
    var expanded = false
    var action: (() -> Void)? = nil

    var body: some View {
        Button { action?(); Haptics.tap() } label: {
            HStack(spacing: 0) {
                Text("\(label): ").font(Theme.Typography.label())
                    .foregroundStyle(Theme.Colors.textLo)
                Text(value).font(Theme.Typography.value())
                    .foregroundStyle(Theme.Colors.textHi)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Theme.Colors.textLo)
                    .rotationEffect(.degrees(expanded ? 180 : 0))
            }
            .padding(.horizontal, 22)
            .frame(height: 54)
            .background(Theme.Colors.carbon.opacity(0.82), in: Capsule())
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(action == nil)
    }
}

/// Big quiet glass surface button (`−1 min` / `+1 min`) — no border emphasis,
/// actions that look like calm surfaces.
struct QuietGlassButton: View {
    var title: String
    var height: CGFloat = 74
    var action: () -> Void

    var body: some View {
        Button { action(); Haptics.tap() } label: {
            Text(title)
                .font(Theme.Typography.button())
                .foregroundStyle(Theme.Colors.textHi)
                .frame(maxWidth: .infinity)
                .frame(height: height)
        }
        .buttonStyle(PressableButtonStyle())
        .smokedGlass(radius: 26)
    }
}
