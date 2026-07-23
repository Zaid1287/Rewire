import SwiftUI

/// The web filter's status on the blocker screen.
///
/// RonLab Family A: smoked glass on the Void scene. There's no hero numeral
/// here on purpose — the idea this card carries is binary coverage, not a
/// quantity, so it takes the status-dot motif and `Label: Value` rows instead
/// of a number inflated to look like data.
///
/// The "blocked something you need" affordance is deliberately on the card
/// rather than buried in a submenu. In the competitor's reviews a false
/// positive reliably ends with the whole blocker switched off and left off —
/// the exit has to be at least as easy to find as the off switch.
struct WebFilterCard: View {
    var isOn: Bool
    var allowedCount: Int
    var blockedCount: Int
    var onOpenExceptions: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(alignment: .top) {
                Text("Web filter")
                    .font(Theme.Typography.caption())
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.Colors.textXlo)
                Spacer()
                openCircle
            }

            StatusLabel(color: isOn ? Theme.Colors.good : Theme.Colors.textTertiary,
                        text: isOn ? "Filtering adult sites" : "Off",
                        textColor: Theme.Colors.textHi)

            VStack(alignment: .leading, spacing: 6) {
                labelValue("Covers", "every browser + in-app")
                labelValue("Allowed", allowedCount == 0 ? "none"
                                        : "\(allowedCount) site\(allowedCount == 1 ? "" : "s")")
                if blockedCount > 0 {
                    labelValue("Also blocked",
                               "\(blockedCount) site\(blockedCount == 1 ? "" : "s")")
                }
            }

            Button(action: onOpenExceptions) {
                Text("Blocked something you need?")
                    .font(Theme.Typography.button())
                    .foregroundStyle(Theme.Colors.textHi)
                    .frame(maxWidth: .infinity)
                    .frame(height: 62)
                    .background {
                        Capsule()
                            .fill(Color.white.opacity(0.06))
                            .overlay(Capsule().strokeBorder(Color.white.opacity(0.12),
                                                            lineWidth: 1))
                    }
            }
            .buttonStyle(PressableButtonStyle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .smokedGlass(radius: 32)
    }

    /// The kit's "open" affordance — 34pt glass circle, top-right of the card.
    private var openCircle: some View {
        Button(action: onOpenExceptions) {
            Image(systemName: "arrow.up.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.Colors.textHi)
                .frame(width: 34, height: 34)
                .background(Circle().fill(Color.white.opacity(0.06)))
                .overlay(Circle().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
        }
        .buttonStyle(PressableButtonStyle())
    }

    private func labelValue(_ label: String, _ value: String) -> some View {
        HStack(spacing: 6) {
            Text("\(label):").foregroundStyle(Theme.Colors.textLo)
            Text(value).foregroundStyle(Theme.Colors.textHi)
            Spacer(minLength: 0)
        }
        .font(Theme.Typography.label())
    }
}

#Preview {
    VStack(spacing: 14) {
        WebFilterCard(isOn: true, allowedCount: 2, blockedCount: 1, onOpenExceptions: {})
        WebFilterCard(isOn: false, allowedCount: 0, blockedCount: 0, onOpenExceptions: {})
    }
    .screenPadding()
    .frame(maxHeight: .infinity)
    .background { SceneBackground(kind: .void) }
}
