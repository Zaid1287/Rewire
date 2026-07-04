import SwiftUI

/// Panic Button premium sheet (IMG_5456): siren, three benefit rows, and an
/// "Unlock Premium Features" CTA.
struct PanicSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let points: [(String, String)] = [
        ("Saves your streak", "Stay safe with the panic button."),
        ("You will need this", "Your first 30 days won't be easy."),
        ("Reach your goals faster", "This will be a game-changer for you.")
    ]

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Capsule().fill(Theme.Colors.textTertiary).frame(width: 40, height: 5)
                .padding(.top, Theme.Spacing.sm)

            Spacer()

            SirenIcon()

            Text("Panic Button")
                .font(Theme.Typography.title())
                .foregroundStyle(Theme.Colors.textPrimary)

            VStack(spacing: 0) {
                ForEach(Array(points.enumerated()), id: \.offset) { idx, p in
                    HStack(alignment: .top, spacing: Theme.Spacing.md) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.white, Theme.Colors.green)
                            .font(.system(size: 24))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(p.0).font(Theme.Typography.headline())
                                .foregroundStyle(Theme.Colors.textPrimary)
                            Text(p.1).font(Theme.Typography.body())
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, Theme.Spacing.md)
                    if idx < points.count - 1 { RowDivider() }
                }
            }
            .screenPadding()

            PrimaryButton(title: "Unlock Premium Features") { dismiss() }
                .screenPadding()

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background)
    }
}

/// Red rotating-siren icon with light rays.
struct SirenIcon: View {
    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                Capsule()
                    .fill(Color(hex: 0xF08A5D))
                    .frame(width: 3, height: 14)
                    .offset(y: -40)
                    .rotationEffect(.degrees(Double(i) / 8 * 360))
            }
            Image(systemName: "light.beacon.max.fill")
                .font(.system(size: 44))
                .foregroundStyle(Theme.Colors.red)
        }
        .frame(width: 100, height: 100)
    }
}

#Preview { PanicSheet() }
