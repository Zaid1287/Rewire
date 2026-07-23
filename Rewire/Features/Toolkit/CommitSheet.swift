import SwiftUI

/// Pick how long to lock the blocker in. Deliberately a decision made while
/// calm and motivated — that asymmetry between the person choosing and the
/// person who'll later want out is the whole mechanism.
///
/// RonLab: the mockup's radio-row pattern (62pt row, white 5% fill, hairline
/// outline; selected gets the butter ring + butter wash + butter dot), on the
/// Void scene with the white capsule as the primary action.
struct CommitSheet: View {
    var onCommit: (TimeInterval) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selected = 2      // 1 week — the reviewer's own example

    var body: some View {
        // The options scroll and the CTA is pinned. Laid out as one plain
        // VStack, the content overflows a medium detent (or any smaller device,
        // or larger Dynamic Type) and pushes "Lock it in" off the bottom, where
        // it can't be tapped — the button looks present and does nothing.
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    content
                }
            }
            .scrollBounceBehavior(.basedOnSize)

            PrimaryButton(title: "Lock it in") {
                onCommit(CommitmentLock.options[selected].duration)
                dismiss()
            }

            Text("You can always add more to block — you just can't take it away until the commitment ends.")
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Colors.textXlo)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.top, Theme.Spacing.sm)
                .padding(.bottom, Theme.Spacing.lg)
        }
        .screenPadding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background { SceneBackground(kind: .void) }
    }

    private var content: some View {
        Group {
            Text("Commitment")
                .font(Theme.Typography.caption())
                .tracking(1.6)
                .foregroundStyle(Theme.Colors.textXlo)
                .padding(.top, Theme.Spacing.xl)

            Text("Lock the blocker for")
                .font(Theme.Typography.title())
                .foregroundStyle(Theme.Colors.textHi)
                .padding(.top, Theme.Spacing.sm)

            Text("You're choosing this while it's easy. Later, turning the blocker off will cost a \(Int(CommitmentLock.coolingOff / 60))-minute wait.")
                .font(Theme.Typography.label())
                .foregroundStyle(Theme.Colors.textLo)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Theme.Spacing.sm)

            VStack(spacing: 10) {
                ForEach(Array(CommitmentLock.options.enumerated()), id: \.offset) { i, option in
                    optionRow(option.label, index: i)
                }
            }
            .padding(.top, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.lg)
        }
    }

    private func optionRow(_ label: String, index: Int) -> some View {
        let isSelected = index == selected
        return Button {
            Haptics.select()
            selected = index
        } label: {
            HStack(spacing: 14) {
                // Butter ring + dot — the one active element on the screen.
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Theme.Colors.butter : Color.white.opacity(0.3),
                                      lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                    if isSelected {
                        Circle().fill(Theme.Colors.butter).frame(width: 10, height: 10)
                    }
                }
                Text(label)
                    .font(Theme.Typography.body())
                    .foregroundStyle(Theme.Colors.textHi)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .frame(height: 62)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(isSelected ? Theme.Colors.butter.opacity(0.07)
                                     : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(isSelected ? Theme.Colors.butter
                                                     : Color.white.opacity(0.10),
                                          lineWidth: isSelected ? 1.5 : 1))
            }
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .animation(Theme.Motion.standard, value: isSelected)
    }
}

#Preview { CommitSheet { _ in } }
