import SwiftUI

/// Floating capsule tab bar. Active item shows a green icon+label inside a
/// pill; others are white/secondary. Recovery carries a red "1" badge.
struct RewireTabBar: View {
    @Binding var selection: AppState.Tab

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
        .themeShadow(Theme.Shadows.floating)
        .padding(.horizontal, Theme.Spacing.md)
    }

    private func tabButton(_ tab: AppState.Tab) -> some View {
        let active = tab == selection
        return Button {
            Haptics.select()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { selection = tab }
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: tab.symbol)
                        .font(.system(size: 20, weight: .regular))
                        .frame(height: 24)
                    if let count = tab.badgeCount {
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
