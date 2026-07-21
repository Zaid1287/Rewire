import SwiftUI

/// Shared layout for question screens: optional back button, optional gem pill,
/// optional progress bar, a large left-aligned question title with optional
/// subtitle, then the options pinned toward the bottom.
struct QuestionScaffold<Options: View>: View {
    var showsBack: Bool = false
    var onBack: (() -> Void)? = nil
    var gemCount: Int? = nil
    var progress: Double? = nil
    let question: String
    var subtitle: String? = nil
    var centeredTitle: Bool = false
    var topSymbol: String? = nil
    @ViewBuilder var options: Options

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top bar: back + gems
            HStack {
                if showsBack { CircleBackButton { onBack?() } }
                Spacer()
                if let gemCount { GemPill(count: gemCount) }
            }
            .padding(.horizontal, Theme.Spacing.screen)
            .padding(.top, Theme.Spacing.xs)
            .frame(minHeight: 44)

            if let progress {
                ProgressBarView(value: progress, height: 8)
                    .padding(.horizontal, Theme.Spacing.screen)
                    .padding(.top, Theme.Spacing.sm)
            }

            // Title block
            VStack(alignment: centeredTitle ? .center : .leading, spacing: Theme.Spacing.sm) {
                if let topSymbol {
                    Image(systemName: topSymbol)
                        .font(.system(size: 30, weight: .regular))
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .frame(width: 60, height: 60)
                        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md)
                            .stroke(Theme.Colors.textPrimary, lineWidth: 2))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                Text(question)
                    .font(Theme.Typography.title())
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .multilineTextAlignment(centeredTitle ? .center : .leading)
                    .frame(maxWidth: .infinity, alignment: centeredTitle ? .center : .leading)
                if let subtitle {
                    Text(subtitle)
                        .font(Theme.Typography.cardTitle())
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .padding(.horizontal, Theme.Spacing.screen)
            .padding(.top, Theme.Spacing.xl)

            Spacer(minLength: Theme.Spacing.xl)

            VStack(spacing: Theme.Spacing.sm) {
                options
            }
            .padding(.horizontal, Theme.Spacing.screen)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background { SceneBackground(kind: .void) }
    }
}
