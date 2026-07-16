import SwiftUI

/// Floating Liquid Glass tab dock, Reddit-style: scrolling down folds it into
/// an icon-only pill docked at the LEFT edge; scrolling up (or tapping the
/// pill) opens the full four-tab bar. Scroll direction is reported by
/// `collapsesDock()` on each tab's ScrollView. Progress carries the
/// unclaimed-badge count in both states.
struct RewireTabBar: View {
    @Binding var selection: AppState.Tab
    /// Folded (icon pill, left) vs open (full dock). Owned by AppState so the
    /// tab screens' scroll views can drive it.
    @Binding var isCollapsed: Bool
    /// Live unclaimed-badge count for the Progress tab; overrides the static
    /// sample badge. nil keeps `Tab.badgeCount`, 0 hides the badge.
    var progressBadgeCount: Int? = nil
    /// Measured bar width — drives finger-position → tab mapping while scrubbing.
    @State private var barWidth: CGFloat = 0
    /// Whether a scrub drag is in flight — the active tab pops slightly while true.
    @State private var scrubbing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Lets the active pill slide between tabs instead of jumping.
    @Namespace private var pillNamespace

    /// The fold/open morph is a momentum-y, Dynamic-Island moment.
    private var morph: Animation {
        reduceMotion ? Theme.Motion.quick : Theme.Motion.emphasized
    }

    var body: some View {
        // ONE identity-stable glass capsule whose content switches — the
        // capsule itself animates between widths and positions (Dynamic
        // Island-style morph). No matchedGeometryEffect on the glass: MGE
        // layered onto glassEffect breaks hit-testing of everything inside it.
        HStack(spacing: 0) {
            if isCollapsed {
                collapsedContent
            } else {
                ForEach(AppState.Tab.allCases, id: \.rawValue) { tab in
                    tabButton(tab)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.xs)
        .padding(.vertical, Theme.Spacing.xs)
        // Liquid Glass to match the floating top bars — one material language.
        .liquidGlass(in: Capsule())
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { barWidth = geo.size.width }
                    .onChange(of: geo.size.width) { _, w in barWidth = w }
            }
        )
        // Instagram-style scrub: drag anywhere on the open bar and the
        // selection follows the finger live. simultaneousGesture so it also
        // fires when the drag starts on a tab item.
        .simultaneousGesture(
            DragGesture(minimumDistance: 12)
                .onChanged { value in
                    guard !isCollapsed else { return }
                    if !scrubbing { withAnimation(Theme.Motion.emphasized) { scrubbing = true } }
                    scrub(to: value.location.x)
                }
                .onEnded { _ in
                    guard !isCollapsed else { return }
                    withAnimation(Theme.Motion.emphasized) { scrubbing = false }
                }
        )
        .themeShadow(Theme.Shadows.floating)
        // Folded pill parks at the leading edge; the open dock is centered.
        .frame(maxWidth: .infinity, alignment: isCollapsed ? .leading : .center)
        .padding(.horizontal, Theme.Spacing.md)
    }

    // MARK: Collapsed — just the active tab's icon, docked left

    private var collapsedContent: some View {
        Image(systemName: selection.activeSymbol)
            .font(.system(size: 20, weight: .regular))
            .foregroundStyle(Theme.Colors.green)
            .frame(width: 44, height: 44)
            .overlay(alignment: .topTrailing) {
                // Keep the unclaimed-badge signal alive while Progress is hidden.
                if selection != .progress, let count = progressBadgeCount, count > 0 {
                    CountBadge(count: count)
                        .scaleEffect(0.72)
                        .offset(x: 6, y: -2)
                }
            }
            .contentShape(Circle())
            .onTapGesture {
                Haptics.tap()
                withAnimation(morph) { isCollapsed = false }
            }
            .transition(.opacity)
    }

    /// Select whichever tab sits under the finger's x position.
    private func scrub(to x: CGFloat) {
        guard barWidth > 0 else { return }
        let tabs = AppState.Tab.allCases
        let slot = Int(x / (barWidth / CGFloat(tabs.count)))
        let tab = tabs[min(tabs.count - 1, max(0, slot))]
        guard tab != selection else { return }
        Haptics.select()
        // Scrub carries finger momentum — the bouncy spring is earned here.
        withAnimation(reduceMotion ? Theme.Motion.quick : Theme.Motion.emphasized) { selection = tab }
    }

    private func badgeCount(for tab: AppState.Tab) -> Int? {
        if tab == .progress, let progressBadgeCount { return progressBadgeCount }
        return tab.badgeCount
    }

    // Plain content + onTapGesture, NOT a Button: SwiftUI Buttons inside this
    // morphing glass container stop receiving taps once the content branches
    // (gestures keep working — verified live). Same fix as the collapsed pill.
    private func tabButton(_ tab: AppState.Tab) -> some View {
        let active = tab == selection
        return Group {
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
            .scaleEffect(active && scrubbing && !reduceMotion ? 1.08 : 1)
            .contentShape(Rectangle())
            .onTapGesture {
                Haptics.select()
                // Plain tap has no momentum — no-overshoot spring (highest-
                // frequency action; bounce here reads as sluggish by day two).
                withAnimation(reduceMotion ? Theme.Motion.quick : Theme.Motion.snappy) { selection = tab }
            }
        }
        // Reddit/Instagram-style dock ripple from the touch point.
        .tapRipple()
        .transition(.opacity)
    }
}

/// Folds the dock on scroll-down, opens it on scroll-up (Reddit-style).
/// Attach to each tab's ScrollView. Needs iOS 18's scroll geometry API —
/// on earlier OSes the dock simply stays open.
extension View {
    func collapsesDock() -> some View { modifier(DockScrollCollapse()) }
}

private struct DockScrollCollapse: ViewModifier {
    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.onScrollGeometryChange(for: CGFloat.self) { geo in
                geo.contentOffset.y + geo.contentInsets.top
            } action: { old, new in
                let delta = new - old
                let target: Bool
                if new <= 24 { target = false }        // near the top: always open
                else if delta > 6 { target = true }    // scrolling down: fold
                else if delta < -6 { target = false }  // scrolling up: open
                else { return }                        // hysteresis — ignore jitter
                guard appState.dockCollapsed != target else { return }
                withAnimation(reduceMotion ? Theme.Motion.quick : Theme.Motion.emphasized) {
                    appState.dockCollapsed = target
                }
            }
        } else {
            content
        }
    }
}

#Preview {
    ZStack {
        Theme.Colors.background.ignoresSafeArea()
        VStack {
            Spacer()
            RewireTabBar(selection: .constant(.today), isCollapsed: .constant(false))
            RewireTabBar(selection: .constant(.today), isCollapsed: .constant(true))
        }
    }
}
