import SwiftUI

extension Color {
    /// Hex initializer supporting `RRGGBB` and `AARRGGBB`.
    init(hex: UInt32, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }

    /// Adaptive color that resolves per the current light/dark trait.
    init(light: UInt32, dark: UInt32) {
        self.init(UIColor { trait in
            UIColor(Color(hex: trait.userInterfaceStyle == .dark ? dark : light))
        })
    }
}

extension Theme {
    /// Semantic color palette inferred from the screenshots.
    /// Neutrals are adaptive (light/dark); accents are fixed across modes.
    enum Colors {
        // Backgrounds & surfaces
        static let background   = Color(light: 0xF2F2F7, dark: 0x0D0D0F)   // screen bg
        static let surface      = Color(light: 0xFFFFFF, dark: 0x1C1C1E)   // cards
        static let surface2     = Color(light: 0xEFEFF4, dark: 0x262628)   // rows on cards / inputs
        static let surface3     = Color(light: 0xE3E3E8, dark: 0x323234)   // pressed / raised
        static let divider      = Color(light: 0xD9D9DE, dark: 0x2C2C2E)   // hairline separators

        // Brand
        static let primary      = Color(hex: 0x4F46E5)   // indigo CTA
        static let primaryHi    = Color(hex: 0x5B52F0)   // gradient top
        static let primaryLo    = Color(hex: 0x4338CA)   // gradient bottom

        // Accents
        static let green        = Color(hex: 0x22C55E)   // success / active
        static let greenMint    = Color(hex: 0x3DDC97)   // progress fill / "with Rewire"
        static let flame        = Color(hex: 0xF15A29)   // streak flame / offer
        static let red          = Color(hex: 0xFF3B30)   // quiz letters / streak break
        static let redSoft      = Color(hex: 0xEF4444)
        static let gold         = Color(hex: 0xF5B301)   // treasure / coins
        static let star         = Color(hex: 0xF5A623)   // rating stars

        // Full-screen result / mood backgrounds
        static let scoreRed     = Color(hex: 0xC0432E)   // 80% addiction screen bg
        static let scoreBar     = Color(hex: 0x8F2817)   // bars on score screen
        static let testMint     = Color(hex: 0xBAD1BF)   // "Test Completed" bg
        static let testMintText = Color(hex: 0x3B6B4E)
        static let noteYellow   = Color(hex: 0xF3F35C)   // "keep busy" sticky

        // Text
        static let textPrimary   = Color(light: 0x111113, dark: 0xFFFFFF)
        static let textSecondary = Color(light: 0x6E6E73, dark: 0xA1A1AA)
        static let textTertiary  = Color(light: 0xA1A1AA, dark: 0x6E6E73)
        static let textOnColor   = Color.white

        // Repeated non-palette accents (promoted from inline hex call sites)
        static let blue        = Color(hex: 0x2C6BE0)   // today marker, water stat, feedback icon
        static let greenDark   = Color(hex: 0x2E7D32)   // dark green icon backgrounds
        static let purple      = Color(hex: 0x8B7BF0)   // badges / levels accents
        static let pastelLime  = Color(hex: 0xB6E8A0)   // pastel icon bg
        static let blueLight   = Color(hex: 0x6FB2FF)   // gem tint

        // Pastel superpower-icon backgrounds
        static let pastelGreen   = Color(hex: 0xBFE8A6)
        static let pastelTan     = Color(hex: 0xE7D3AE)
        static let pastelPink    = Color(hex: 0xF7C9CF)
        static let pastelAmber   = Color(hex: 0xF3E2A6)
        static let pastelMint    = Color(hex: 0xC9EBD0)
        static let pastelGray    = Color(hex: 0xD9D9DE)
        static let pastelRose    = Color(hex: 0xF3C7C0)
        static let pastelLav     = Color(hex: 0xD9D4EE)
        static let pastelPeach   = Color(hex: 0xF6D2B8)

        // Gradients
        static let primaryGradient = LinearGradient(
            colors: [primaryHi, primaryLo],
            startPoint: .top, endPoint: .bottom
        )
        static let flameGradient = LinearGradient(
            colors: [Color(hex: 0xFF7A2F), Color(hex: 0xF15A29)],
            startPoint: .top, endPoint: .bottom
        )
    }
}
