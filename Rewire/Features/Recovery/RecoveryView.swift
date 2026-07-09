import SwiftUI

/// Recovery tab (IMG_5460): recovery ring, a Superpowers preview, the badges &
/// levels collection, and "make your streaks easier" feature rows.
struct RecoveryView: View {
    enum Route: Hashable { case superpowers, badges, levels }
    @Environment(GemStore.self) private var gems
    @Environment(StreakStore.self) private var streak
    @State private var path: [Route] = []

    /// Recovery % — current streak against the standard 90-day rewire window.
    private var recoveryPercent: Int {
        min(100, Int(streak.elapsed / 86_400 / 90 * 100))
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                NavHeader(title: "Recovery")
                ScrollView {
                    VStack(spacing: Theme.Spacing.xl) {
                        recoveryHeader
                        superpowersPreview
                        collection
                        easier
                    }
                    .screenPadding()
                    .padding(.top, Theme.Spacing.lg)
                    .padding(.bottom, Theme.Spacing.tabBarClearance)
                }
            }
            .background(Theme.Colors.background)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .superpowers: SuperpowersView()
                case .badges:      BadgesView()
                case .levels:      LevelsView()
                }
            }
        }
        .tint(Theme.Colors.green)
    }

    private var recoveryHeader: some View {
        HStack(spacing: Theme.Spacing.lg) {
            RecoveryRing(percent: recoveryPercent)
                .frame(width: 92, height: 92)
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack(spacing: Theme.Spacing.xs) {
                    Text("Your recovery")
                        .font(Theme.Typography.cardTitle())
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Image(systemName: "info.circle")
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                Text("Keep your streak to recover completely.")
                    .font(Theme.Typography.body())
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    private var superpowersPreview: some View {
        VStack(spacing: Theme.Spacing.md) {
            SectionHeader(title: "Superpowers") {
                LinkButton(title: "Show All") { path.append(.superpowers) }
            }
            Card(padding: Theme.Spacing.md) {
                VStack(spacing: 0) {
                    BenefitRow(benefit: SampleData.benefits[0], showProgress: true, progress: 0.08)
                    RowDivider()
                    BenefitRow(benefit: SampleData.benefits[1], showProgress: true, progress: 0.08)
                }
            }
        }
    }

    private var collection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader("My Collection")
            HStack(spacing: Theme.Spacing.md) {
                collectionCard(icon: "rosette", iconColor: Theme.Colors.purple,
                               title: "Badges", badge: 2, value: "\(gems.claimedBadges.count)", unit: "badges") {
                    path.append(.badges)
                }
                collectionCard(icon: "trophy.fill", iconColor: Theme.Colors.gold,
                               title: "Levels",
                               badge: nil,
                               value: SampleData.levels.first(where: { $0.rank == gems.currentLevel })?.name ?? "Newcomer",
                               unit: nil) {
                    path.append(.levels)
                }
            }
        }
    }

    private func collectionCard(icon: String, iconColor: Color, title: String,
                                badge: Int?, value: String, unit: String?,
                                action: @escaping () -> Void) -> some View {
        Button(action: { Haptics.tap(); action() }) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack(spacing: 6) {
                    Image(systemName: icon).foregroundStyle(iconColor)
                    Text(title.uppercased())
                        .font(Theme.Typography.sectionHeader())
                        .foregroundStyle(iconColor)
                    Image(systemName: "chevron.right").font(.system(size: 11, weight: .bold))
                        .foregroundStyle(iconColor)
                    if let badge { Spacer(); CountBadge(count: badge) }
                }
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value).font(Theme.Typography.statNumber())
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                    if let unit {
                        Text(unit).font(Theme.Typography.body())
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var easier: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader("Make your streaks easier")
            VStack(spacing: 0) {
                ForEach(Array(SampleData.recoveryEasier.enumerated()), id: \.element.id) { idx, item in
                    FeatureRow(item: item).padding(.horizontal, Theme.Spacing.md)
                    if idx < SampleData.recoveryEasier.count - 1 { RowDivider(inset: 64) }
                }
            }
            .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
        }
    }
}

/// Circular recovery progress ring with a leading dot cap.
struct RecoveryRing: View {
    let percent: Int
    var body: some View {
        ZStack {
            Circle().stroke(Theme.Colors.surface2, lineWidth: 8)
            Circle()
                .trim(from: 0, to: max(0.01, CGFloat(percent) / 100))
                .stroke(Theme.Colors.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(percent)%")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.Colors.textPrimary)
        }
    }
}

#Preview { RecoveryView().environment(GemStore()).environment(StreakStore()) }
