import SwiftUI

/// A single onboarding quiz question with lettered options (A–E).
struct QuizQuestion: Identifiable {
    let id = UUID()
    let prompt: String
    let options: [String]
}

/// A testimonial rendered as a chat bubble (onboarding social proof).
struct ChatTestimonial: Identifiable {
    let id = UUID()
    let text: String
    let boldPrefix: String?   // leading bold clause, e.g. "Helped me in my journey…"
    let name: String
    let isRight: Bool         // bubble alignment
}

/// A testimonial rendered as a quote card ("How have others changed their lives?").
struct QuoteTestimonial: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    let name: String
    let daysClean: Int
}

/// A benefit row (icon + title + subtitle) used on the benefits screen and
/// reused as a Superpower.
struct Benefit: Identifiable {
    let id = UUID()
    let symbol: String        // SF Symbol or emoji
    let isEmoji: Bool
    let iconTint: Color
    let iconBackground: Color
    let title: String
    let subtitle: String
}

/// The pros/cons rows on the "without / with Rewire" comparison screen.
struct ComparisonPoint: Identifiable {
    let id = UUID()
    let text: String
}
