import SwiftUI

/// Floating capsule tab bar. Active item shows a green icon+label inside a
/// pill; others are white/secondary. Recovery carries a red "1" badge.
struct RewireTabBar: View {
    @Binding var selection: AppState.Tab
    /// Live unclaimed-badge count for the Recovery tab; overrides the static
    /// sample badge. nil keeps `Tab.badgeCount`, 0 hides the badge.
    var recoveryBadgeCount: Int? = nil
    /// Measured bar width — drives finger-position → tab mapping while scrubbing.
    @State private var barWidth: CGFloat = 0
    /// Whether a scrub drag is in flight — the active tab pops slightly while true.
    @State private var scrubbing = false
    /// Lets the active pill slide between tabs instead of jumping.
    @Namespace private var pillNamespace

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
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { barWidth = geo.size.width }
                    .onChange(of: geo.size.width) { _, w in barWidth = w }
            }
        )
        // Instagram-style scrub: drag anywhere on the bar and the selection
        // follows the finger live. simultaneousGesture so it also fires when
        // the drag starts on a tab button (a plain .gesture never would —
        // that's why the old flick version felt dead).
        .simultaneousGesture(
            DragGesture(minimumDistance: 12)
                .onChanged { value in
                    if !scrubbing { withAnimation(Theme.Motion.emphasized) { scrubbing = true } }
                    scrub(to: value.location.x)
                }
                .onEnded { _ in
                    withAnimation(Theme.Motion.emphasized) { scrubbing = false }
                }
        )
        .themeShadow(Theme.Shadows.floating)
        .padding(.horizontal, Theme.Spacing.md)
    }

    /// Select whichever tab sits under the finger's x position.
    private func scrub(to x: CGFloat) {
        guard barWidth > 0 else { return }
        let tabs = AppState.Tab.allCases
        let slot = Int(x / (barWidth / CGFloat(tabs.count)))
        let tab = tabs[min(tabs.count - 1, max(0, slot))]
        guard tab != selection else { return }
        Haptics.select()
        withAnimation(Theme.Motion.emphasized) { selection = tab }
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
            // Pill slides between tabs (matchedGeometryEffect) instead of
            // fading out/in — this is the scrub animation.
            .background {
                if active {
                    Capsule()
                        .fill(Theme.Colors.surface3)
                        .matchedGeometryEffect(id: "pill", in: pillNamespace)
                }
            }
            .scaleEffect(active && scrubbing ? 1.08 : 1)
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
