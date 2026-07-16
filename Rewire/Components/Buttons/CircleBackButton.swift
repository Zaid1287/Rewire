import SwiftUI

/// Ghost circular back button (top-left of most sub-screens): thin stroked
/// circle with a chevron.
struct CircleBackButton: View {
    var symbol: String = "chevron.left"
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.Colors.textPrimary)
                .frame(width: 44, height: 44)
                // Standalone floating glass circle — detached from any bar.
                .liquidGlass(in: Circle())
        }
        .buttonStyle(PressableButtonStyle())
    }
}

/// Green text link with trailing arrow — "ADD DAYS →", "SET GOAL →", "SHOW ALL →".
struct LinkButton: View {
    let title: String
    var trailingSymbol: String? = "arrow.right"
    var color: Color = Theme.Colors.green
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(Theme.Typography.sectionHeader())
                    .tracking(0.5)
                    .textCase(.uppercase)
                if let trailingSymbol {
                    Image(systemName: trailingSymbol).font(.system(size: 13, weight: .bold))
                }
            }
            .foregroundStyle(color)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

#Preview {
    HStack {
        CircleBackButton {}
        LinkButton(title: "Set Goal") {}
    }
    .padding()
    .background(Theme.Colors.background)
}
