import SwiftUI

/// Lettered quiz option (A–E red circle badge + label on a dark card).
/// Onboarding questions (IMG_5428–5431) and relapse "regretful?" prompts.
struct QuizOptionRow: View {
    let letter: String
    let text: String
    var isSelected: Bool = false
    var action: () -> Void = {}

    var body: some View {
        Button(action: { Haptics.select(); action() }) {
            HStack(spacing: Theme.Spacing.md) {
                Text(letter)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Theme.Colors.critical, in: Circle())
                Text(text)
                    .font(Theme.Typography.cardTitle())
                    .foregroundStyle(Theme.Colors.textPrimary)
                Spacer(minLength: 0)
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .stroke(Theme.Colors.good, lineWidth: isSelected ? 2 : 0)
            )
        }
        .buttonStyle(PressableButtonStyle())
    }
}

/// Radio-style option (empty circle → green check). Used by the masturbation-
/// session picker and relapse-reason list.
struct RadioOptionRow: View {
    let text: String
    var isSelected: Bool = false
    var action: () -> Void = {}

    var body: some View {
        Button(action: { Haptics.select(); action() }) {
            HStack(spacing: Theme.Spacing.md) {
                ZStack {
                    Circle().stroke(isSelected ? Theme.Colors.good : Theme.Colors.textTertiary,
                                    lineWidth: 2)
                        .frame(width: 26, height: 26)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 26, height: 26)
                            .background(Theme.Colors.good, in: Circle())
                            .transition(.scale(scale: 0.5).combined(with: .opacity))
                    }
                }
                .animation(Theme.Motion.quick, value: isSelected)
                Text(text)
                    .font(Theme.Typography.cardTitle())
                    .foregroundStyle(Theme.Colors.textPrimary)
                Spacer(minLength: 0)
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .stroke(Theme.Colors.good, lineWidth: isSelected ? 2 : 0)
            )
        }
        .buttonStyle(PressableButtonStyle())
    }
}

extension Int {
    /// 0 → "A", 1 → "B", …
    var optionLetter: String {
        guard let scalar = UnicodeScalar(65 + self) else { return "" }
        return String(Character(scalar))
    }
}
