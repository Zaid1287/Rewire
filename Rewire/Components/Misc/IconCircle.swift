import SwiftUI

/// A circular tinted icon badge — SF Symbol or emoji on a pastel/solid fill.
/// Used by benefit rows, superpowers, and the app logo tile.
struct IconCircle: View {
    let symbol: String
    var isEmoji: Bool = false
    var tint: Color = .white
    var background: Color = Theme.Colors.surface2
    var size: CGFloat = 52
    var stroke: Color? = nil

    var body: some View {
        ZStack {
            Circle().fill(background)
            if let stroke {
                Circle().stroke(stroke, lineWidth: 2)
            }
            if isEmoji {
                Text(symbol).font(.system(size: size * 0.42))
            } else {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.42, weight: .semibold))
                    .foregroundStyle(tint)
            }
        }
        .frame(width: size, height: size)
    }
}

/// Rounded-square tinted icon (Settings rows, app logo, sticky tiles).
struct IconSquare: View {
    let symbol: String
    var isEmoji: Bool = false
    var tint: Color = .white
    var background: Color = Theme.Colors.primary
    var size: CGFloat = 34
    var corner: CGFloat = Theme.Radius.sm

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: corner).fill(background)
            if isEmoji {
                Text(symbol).font(.system(size: size * 0.5))
            } else {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.5, weight: .semibold))
                    .foregroundStyle(tint)
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    HStack(spacing: 16) {
        IconCircle(symbol: "😍", isEmoji: true, background: Theme.Colors.pastelPink)
        IconCircle(symbol: "bolt.fill", tint: .white, background: Theme.Colors.pastelGreen)
        IconSquare(symbol: "circle.lefthalf.filled", background: Theme.Colors.primary)
    }
    .padding()
    .background { SceneBackground(kind: .void) }
}
