import SwiftUI

/// "without / with Rewire" comparison card. Negative variant uses grey minus
/// bullets; positive uses green checks. Both carry an illustration avatar.
struct ComparisonCard: View {
    let title: String
    let titleColor: Color
    let points: [ComparisonPoint]
    let positive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text(title)
                .font(Theme.Typography.cardTitle())
                .foregroundStyle(titleColor)

            ForEach(points) { point in
                HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                    if positive {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Theme.Colors.good)
                    } else {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                    Text(point.text)
                        .font(Theme.Typography.body())
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Illustration avatar placeholder (sad / happy cartoon).
            PlaceholderAvatar(happy: positive)
                .frame(width: 96, height: 96)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, Theme.Spacing.xs)
        }
        .padding(Theme.Spacing.lg)
        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.xl))
    }
}

/// Flat comparison avatars matching the produced asset board: solid brown
/// frown (`avatar_sad`) / orange smile (`avatar_happy`), white eyes + mouth.
struct PlaceholderAvatar: View {
    let happy: Bool
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                Circle().fill(happy ? Color(hex: 0xF0A03C) : Color(hex: 0x8A7B72))
                HStack(spacing: s * 0.20) {
                    Capsule().fill(.white).frame(width: s * 0.075, height: s * 0.15)
                    Capsule().fill(.white).frame(width: s * 0.075, height: s * 0.15)
                }
                .offset(y: -s * 0.10)
                FaceMouth(happy: happy)
                    .stroke(.white, style: StrokeStyle(lineWidth: s * 0.06, lineCap: .round))
                    .frame(width: s * 0.44, height: s * 0.20)
                    .offset(y: s * 0.14)
            }
            .frame(width: s, height: s)
        }
    }
}

/// Smile (U) when happy, frown (∩) otherwise.
struct FaceMouth: Shape {
    let happy: Bool
    func path(in rect: CGRect) -> Path {
        var p = Path()
        if happy {
            p.move(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY),
                           control: CGPoint(x: rect.midX, y: rect.maxY * 1.4))
        } else {
            p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY),
                           control: CGPoint(x: rect.midX, y: rect.minY - rect.maxY * 0.4))
        }
        return p
    }
}
