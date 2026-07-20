import SwiftUI

/// Central design-system namespace. All tokens (colors, type, spacing, radius,
/// shadows) hang off `Theme` so screens never hardcode raw values.
///
/// Neutral tokens (backgrounds, surfaces, text) are adaptive light/dark pairs;
/// accents are fixed. The active scheme is the user's Appearance preference
/// (AppState.appearance, default Dark) applied via preferredColorScheme.
enum Theme {}
