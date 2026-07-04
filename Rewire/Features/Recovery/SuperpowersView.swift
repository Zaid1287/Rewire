import SwiftUI

/// Superpowers list (IMG_5461 / 5462): every benefit with a progress meter and
/// a like counter to tap when experienced.
struct SuperpowersView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var likes: [UUID: Int] = [:]

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(title: "Superpowers", showsBack: true, onBack: { dismiss() })
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    HStack(alignment: .top, spacing: Theme.Spacing.md) {
                        Image(systemName: "info.circle").font(.system(size: 22))
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Text("When you experience one of these superpowers, tap the Like button.")
                            .font(Theme.Typography.cardTitle())
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, Theme.Spacing.md)

                    Card(padding: Theme.Spacing.md) {
                        VStack(spacing: 0) {
                            ForEach(Array(SampleData.benefits.enumerated()), id: \.element.id) { idx, benefit in
                                BenefitRow(benefit: benefit, showProgress: true, progress: 0.08,
                                           likeCount: likes[benefit.id] ?? 0) {
                                    likes[benefit.id, default: 0] += 1
                                }
                                if idx < SampleData.benefits.count - 1 { RowDivider() }
                            }
                        }
                    }
                }
                .screenPadding()
                .padding(.top, Theme.Spacing.md)
                .padding(.bottom, 120)
            }
        }
        .background(Theme.Colors.background)
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview { NavigationStack { SuperpowersView() } }
