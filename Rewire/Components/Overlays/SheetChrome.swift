import SwiftUI

/// Drag capsule + centered title used by all bottom sheets.
struct SheetChrome: View {
    let title: String
    var titleFont: Font = Theme.Typography.title()

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Capsule().fill(Theme.Colors.textTertiary).frame(width: 40, height: 5)
                .padding(.top, Theme.Spacing.sm)

            Text(title)
                .font(titleFont)
                .foregroundStyle(Theme.Colors.textPrimary)
        }
    }
}

#Preview {
    VStack {
        SheetChrome(title: "Data Backup")
        Spacer()
    }
    .background(Theme.Colors.background)
}
