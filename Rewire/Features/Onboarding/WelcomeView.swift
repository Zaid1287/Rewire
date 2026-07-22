import SwiftUI

/// Final beat before the main app (was IMG_5439's old-logo splash). Replaced
/// with a skeleton of the Home screen — the new brand-dot mark over shimmering
/// placeholders — so the last frame previews what's loading instead of showing
/// the retired shield logo. Auto-enters the main app after a short beat.
struct WelcomeView: View {
    var onFinish: () -> Void
    @State private var shimmer = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            HStack {
                BrandDots(size: 22, color: Theme.Colors.textHi)
                Spacer()
                skeleton(width: 46, height: 46, radius: 16)
            }
            .padding(.top, Theme.Spacing.xl)

            skeleton(width: 150, height: 18)     // goal pill
                .frame(maxWidth: .infinity, alignment: .center)

            VStack(spacing: 10) {                 // hero block
                skeleton(width: 200, height: 44)
                skeleton(width: 120, height: 16)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.lg)

            HStack(spacing: 12) {                 // stat cards
                skeleton(height: 96, radius: 20)
                skeleton(height: 96, radius: 20)
            }

            skeleton(height: 62, radius: 20)      // panic capsule

            HStack(spacing: 12) {                 // quiet actions
                skeleton(height: 56, radius: 18)
                skeleton(height: 56, radius: 18)
            }
            Spacer()
        }
        .screenPadding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { SceneBackground(kind: .void) }
        .onAppear {
            shimmer = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { onFinish() }
        }
    }

    /// One shimmering placeholder block. Width defaults to fill.
    private func skeleton(width: CGFloat? = nil, height: CGFloat,
                          radius: CGFloat = 8) -> some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(Color.white.opacity(0.06))
            .frame(maxWidth: width ?? .infinity)
            .frame(height: height)
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(LinearGradient(
                        colors: [.clear, Color.white.opacity(0.14), .clear],
                        startPoint: .leading, endPoint: .trailing))
                    .offset(x: shimmer ? 220 : -220)
                    .animation(.linear(duration: 1.2).repeatForever(autoreverses: false),
                               value: shimmer)
                    .mask(RoundedRectangle(cornerRadius: radius, style: .continuous))
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

#Preview { WelcomeView(onFinish: {}) }
