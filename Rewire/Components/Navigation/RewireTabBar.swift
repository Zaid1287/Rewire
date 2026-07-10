import SwiftUI

/// Floating capsule tab bar. Active item shows a green icon+label inside a
/// pill; others are white/secondary. Recovery carries a red "1" badge.
struct RewireTabBar: View {
    @Binding var selection: AppState.Tab
    /// Live unclaimed-badge count for the Recovery tab; overrides the static
    /// sample badge. nil keeps `Tab.badgeCount`, 0 hides the badge.
    var recoveryBadgeCount: Int? = nil

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppState.Tab.allCases, id: \.rawValue) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, Theme.Spacing.xs)
        .padding(.vertical, Theme.Spacing.xs)
        .background(
            Capsule().fill(Theme.Colors.surface.opacity(0.92))
                .overlay(Capsule().stroke(Theme.Colors.divider, lineWidth: 1))
        )
        .gesture(
            // minimumDistance 20 so ordinary taps on the row buttons aren't swallowed.
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    let tabs = AppState.Tab.allCases
                    guard let index = tabs.firstIndex(of: selection) else { return }
                    if value.translation.width < -40, index < tabs.count - 1 {
                        Haptics.select()
                        withAnimation(Theme.Motion.emphasized) { selection = tabs[index + 1] }
                    } else if value.translation.width > 40, index > 0 {
                        Haptics.select()
                        withAnimation(Theme.Motion.emphasized) { selection = tabs[index - 1] }
                    }
                }
        )
        .themeShadow(Theme.Shadows.floating)
        .padding(.horizontal, Theme.Spacing.md)
    }

    private func badgeCount(for tab: AppState.Tab) -> Int? {
        if tab == .recovery, let recoveryBadgeCount { return recoveryBadgeCount }
        return tab.badgeCount
    }

    private func tabButton(_ tab: AppState.Tab) -> some View {
        let active = tab == selection
        return Button {
            Haptics.select()
            withAnimation(Theme.Motion.emphasized) { selection = tab }
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: active ? tab.activeSymbol : tab.symbol)
                        .font(.system(size: 20, weight: .regular))
                        .frame(height: 24)
                    if let count = badgeCount(for: tab), count > 0 {
                        CountBadge(count: count)
                            .scaleEffect(0.72)
                            .offset(x: 14, y: -8)
                    }
                }
                Text(tab.title)
                    .font(Theme.Typography.tab())
            }
            .foregroundStyle(active ? Theme.Colors.green : Theme.Colors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.xs)
            .background(
                Capsule()
                    .fill(active ? Theme.Colors.surface3 : .clear)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Theme.Colors.background.ignoresSafeArea()
        VStack {
            Spacer()
            RewireTabBar(selection: .constant(.home))
        }
    }
}
