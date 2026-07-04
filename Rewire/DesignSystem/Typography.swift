import SwiftUI

extension Theme {
    /// Type scale. Uses the system font (SF Pro); numerals lean on the rounded
    /// design to match the screenshots' timer/stat digits.
    enum Typography {
        static func hero()        -> Font { .system(size: 38, weight: .bold) }
        static func title()       -> Font { .system(size: 32, weight: .bold) }
        static func navTitle()    -> Font { .system(size: 19, weight: .semibold) }
        static func cardTitle()   -> Font { .system(size: 21, weight: .semibold) }
        static func headline()    -> Font { .system(size: 18, weight: .semibold) }
        static func body()        -> Font { .system(size: 17, weight: .regular) }
        static func bodyMedium()  -> Font { .system(size: 17, weight: .medium) }
        static func subtitle()    -> Font { .system(size: 15, weight: .regular) }
        static func caption()     -> Font { .system(size: 13, weight: .regular) }
        static func button()      -> Font { .system(size: 18, weight: .semibold) }
        static func tab()         -> Font { .system(size: 11, weight: .medium) }

        /// UPPERCASE tracked section headers (SHORTCUTS, GOALS, PREFERENCES…).
        static func sectionHeader() -> Font { .system(size: 13, weight: .semibold) }

        // Numeric / display (rounded)
        static func statNumber()  -> Font { .system(size: 30, weight: .bold, design: .rounded) }
        static func bigNumber()   -> Font { .system(size: 52, weight: .bold, design: .rounded) }
        static func timerDigit()  -> Font { .system(size: 30, weight: .bold, design: .rounded) }
    }
}

/// Convenience view modifiers so call sites read `.sectionHeaderStyle()` etc.
extension View {
    func sectionHeaderStyle() -> some View {
        self.font(Theme.Typography.sectionHeader())
            .tracking(0.8)
            .foregroundStyle(Theme.Colors.textSecondary)
            .textCase(.uppercase)
    }
}
