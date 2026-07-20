import SwiftUI

extension Theme {
    /// Type scale — Urbanist throughout (RonLab language). Hierarchy comes from
    /// size and opacity, not weight: nothing heavier than SemiBold, and SemiBold
    /// only on Family B display headlines.
    enum Typography {
        private static func urbanist(_ name: String, _ size: CGFloat) -> Font {
            .custom(name, fixedSize: size)
        }

        // Display
        static func hero()        -> Font { urbanist(Fonts.extraLight, 38) }
        static func title()       -> Font { urbanist(Fonts.light, 32) }
        static func displayHeadline() -> Font { urbanist(Fonts.semiBold, 38) }   // Family B only
        static func navTitle()    -> Font { urbanist(Fonts.medium, 19) }
        static func cardTitle()   -> Font { urbanist(Fonts.regular, 19) }
        static func headline()    -> Font { urbanist(Fonts.medium, 18) }

        // Text
        static func body()        -> Font { urbanist(Fonts.regular, 17) }
        static func bodyMedium()  -> Font { urbanist(Fonts.medium, 17) }
        static func subtitle()    -> Font { urbanist(Fonts.regular, 15) }
        static func caption()     -> Font { urbanist(Fonts.regular, 13) }
        static func button()      -> Font { urbanist(Fonts.regular, 17) }
        static func tab()         -> Font { urbanist(Fonts.medium, 12) }
        static func sectionHeader() -> Font { urbanist(Fonts.medium, 13) }

        // Label: Value pattern
        static func label()       -> Font { urbanist(Fonts.regular, 15) }
        static func value()       -> Font { urbanist(Fonts.regular, 17) }

        // Numeric / display
        static func heroNumeral(_ size: CGFloat = 88) -> Font { urbanist(Fonts.thin, size) }
        static func statNumber()  -> Font { urbanist(Fonts.light, 30) }
        static func bigNumber()   -> Font { urbanist(Fonts.extraLight, 52) }
        static func timerDigit()  -> Font { urbanist(Fonts.light, 30) }
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

    /// Hero numeral + small unit suffix at 35% — `47 days`, `52 %`.
    func heroNumeralStyle(size: CGFloat = 88) -> some View {
        self.font(Theme.Typography.heroNumeral(size))
            .kerning(size * -0.02)
            .monospacedDigit()
            .contentTransition(.numericText())
    }
}
