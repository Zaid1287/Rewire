import SwiftUI

extension Theme {
    /// Corner-radius scale inferred from the screenshots.
    enum Radius {
        static let xs:  CGFloat = 6    // small badges (POPULAR, PLUS)
        static let sm:  CGFloat = 10   // icon squares
        static let md:  CGFloat = 12   // option rows, tiles
        static let lg:  CGFloat = 16   // cards, shortcut tiles
        static let xl:  CGFloat = 20   // large cards, sheet inner
        static let sheet: CGFloat = 24 // bottom-sheet top corners
        static let pill: CGFloat = 999 // fully rounded buttons / capsules
    }
}
