import SwiftUI

/// Central design-system namespace. All tokens (colors, type, spacing, radius,
/// shadows) hang off `Theme` so screens never hardcode raw values.
///
/// The app ships dark-only (matching every screenshot). `UIUserInterfaceStyle`
/// is forced to Dark in the target settings, so semantic colors below are the
/// literal palette rather than adaptive light/dark pairs.
enum Theme {}
