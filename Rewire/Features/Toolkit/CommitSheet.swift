import SwiftUI

/// Pick how long to lock the blocker in. Deliberately a decision made while
/// calm and motivated — that asymmetry between the person choosing and the
/// person who'll later want out is the whole mechanism.
struct CommitSheet: View {
    var onCommit: (TimeInterval) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selected = 2      // 1 week — the reviewer's own example

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Lock the blocker for")
                    .font(Theme.Typography.title())
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text("You're choosing this while it's easy. Later, turning the blocker off will cost a \(Int(CommitmentLock.coolingOff / 60))-minute wait.")
                    .font(Theme.Typography.body())
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, Theme.Spacing.lg)

            VStack(spacing: 0) {
                ForEach(Array(CommitmentLock.options.enumerated()), id: \.offset) { i, option in
                    Button {
                        Haptics.select()
                        selected = i
                    } label: {
                        HStack {
                            Text(option.label)
                                .font(Theme.Typography.body())
                                .foregroundStyle(Theme.Colors.textPrimary)
                            Spacer()
                            Image(systemName: i == selected ? "largecircle.fill.circle" : "circle")
                                .foregroundStyle(i == selected ? Theme.Colors.butter
                                                              : Theme.Colors.textTertiary)
                        }
                        .padding(Theme.Spacing.md)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if i < CommitmentLock.options.count - 1 { RowDivider(inset: Theme.Spacing.md) }
                }
            }
            .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))

            Spacer(minLength: 0)

            PrimaryButton(title: "Lock it in") {
                onCommit(CommitmentLock.options[selected].duration)
                dismiss()
            }
            .padding(.bottom, Theme.Spacing.lg)
        }
        .screenPadding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background { SceneBackground(kind: .void) }
    }
}

#Preview { CommitSheet { _ in } }
