import SwiftUI

/// Chat-style testimonial bubble (onboarding social proof). Left- or
/// right-aligned with an avatar initial circle.
struct TestimonialBubble: View {
    let item: ChatTestimonial

    var body: some View {
        HStack {
            if item.isRight { Spacer(minLength: Theme.Spacing.xxl) }
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text(attributed)
                    .font(Theme.Typography.body())
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: Theme.Spacing.xs) {
                    Spacer(minLength: 0)
                    Text(item.name)
                        .font(Theme.Typography.subtitle())
                        .foregroundStyle(Theme.Colors.textSecondary)
                    AvatarInitial(name: item.name)
                }
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.xl))
            if !item.isRight { Spacer(minLength: Theme.Spacing.xxl) }
        }
    }

    private var attributed: AttributedString {
        var result = AttributedString()
        if let bold = item.boldPrefix {
            var b = AttributedString(bold)
            b.font = .system(size: 17, weight: .bold)
            result += b
        }
        result += AttributedString(item.text)
        return result
    }
}

/// Circle with a single initial (testimonial avatar / chat sender).
struct AvatarInitial: View {
    let name: String
    var size: CGFloat = 34
    var body: some View {
        Text(String(name.prefix(1)))
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(Theme.Colors.textPrimary)
            .frame(width: size, height: size)
            .background(Theme.Colors.surface2, in: Circle())
            .overlay(Circle().stroke(Theme.Colors.divider, lineWidth: 1))
    }
}

/// Quote-card testimonial ("How have others changed their lives?").
struct TestimonialQuoteCard: View {
    let item: QuoteTestimonial

    var body: some View {
        Card(padding: Theme.Spacing.lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack(alignment: .top, spacing: Theme.Spacing.xs) {
                    Text("\u{201C}")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(Theme.Colors.good)
                        .offset(y: 8)
                    Text(item.title)
                        .font(Theme.Typography.headline())
                        .foregroundStyle(Theme.Colors.good)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text(item.body)
                    .font(Theme.Typography.body())
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 6) {
                    Spacer()
                    Image(systemName: "person.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.Colors.textSecondary)
                    Text("\(item.name), \(item.daysClean) days clean")
                        .font(Theme.Typography.subtitle())
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
        }
    }
}
