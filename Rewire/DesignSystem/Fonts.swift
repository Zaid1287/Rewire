import SwiftUI
import CoreText

extension Theme {
    /// Bundled Urbanist faces (SIL OFL). Registered at launch — the project uses a
    /// generated Info.plist, so runtime registration replaces UIAppFonts.
    enum Fonts {
        static let thin       = "Urbanist-Thin"
        static let extraLight = "Urbanist-ExtraLight"
        static let light      = "Urbanist-Light"
        static let regular    = "Urbanist-Regular"
        static let medium     = "Urbanist-Medium"
        static let semiBold   = "Urbanist-SemiBold"

        private static let all = [thin, extraLight, light, regular, medium, semiBold]

        /// Idempotent; call once from `RewireApp.init` before any view renders.
        static func register() {
            for name in all {
                guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else {
                    assertionFailure("Missing bundled font \(name).ttf")
                    continue
                }
                // Already-registered errors are fine (previews re-run init).
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }
}
