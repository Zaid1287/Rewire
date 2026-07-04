import SwiftUI

/// Centered nav title with optional leading back button and trailing accessory.
/// Sits under the status bar with a hairline bottom border on some screens.
struct NavHeader<Trailing: View>: View {
    let title: String
    var showsBack: Bool = false
    var onBack: (() -> Void)? = nil
    var showsDivider: Bool = true
    @ViewBuilder var trailing: Trailing

    var body: some View {
        ZStack {
            Text(title)
                .font(Theme.Typography.navTitle())
                .foregroundStyle(Theme.Colors.textPrimary)

            HStack {
                if showsBack {
                    CircleBackButton { onBack?() }
                }
                Spacer()
                trailing
            }
        }
        .frame(height: 44)
        .padding(.horizontal, Theme.Spacing.screen)
        .padding(.vertical, Theme.Spacing.xs)
        .overlay(alignment: .bottom) {
            if showsDivider { RowDivider() }
        }
    }
}

extension NavHeader where Trailing == EmptyView {
    init(title: String, showsBack: Bool = false, showsDivider: Bool = true, onBack: (() -> Void)? = nil) {
        self.init(title: title, showsBack: showsBack, onBack: onBack, showsDivider: showsDivider) { EmptyView() }
    }
}

#Preview {
    VStack(spacing: 0) {
        NavHeader(title: "My Badges", showsBack: true) {}
        NavHeader(title: "Settings") {
            CoinPill(count: 0)
        }
    }
    .background(Theme.Colors.background)
}
