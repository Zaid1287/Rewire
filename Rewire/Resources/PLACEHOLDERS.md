# Placeholder assets

An **asset board** (`design/Rewire Assets.pdf`) was produced for these items.
It's a vector reference, not separate image files — so the marks are recreated
in-code as scalable SwiftUI vectors matching the board. Icon-type marks are
**final**; photographic frames still need real art.

## Vector marks — final (recreated in code to match the board)
| View | Where | Board name |
|---|---|---|
| `AppLogo` / `AppLogoSmall` | Splash, hero chip, Settings | AppLogo / AppLogoSmall |
| `GemIcon` | Gem currency glyph | gem |
| `CoinIcon` | Coin currency glyph | coin |
| `ChestMark` | Reward box | reward_chest |
| Superpower glyphs (`SampleData.benefits`) | Benefits / Superpowers | 10 pastel glyphs |
| `PlaceholderAvatar(happy:)` | Comparison cards | avatar_sad / avatar_happy |

## Photographic assets — now imported from the board (real images)
Extracted from `design/Rewire Assets.pdf` into `Assets.xcassets`:
| Image asset | Used by | Notes |
|---|---|---|
| `onboarding_hero` (560×955) | `HeroImagePlaceholder` | Green-ring brand-motif hero + shield, dark scrim |
| `reminders_phone` (555×1134) | `ReminderCollage` | Lock-screen check-in notification mockup |
| `reminders_watch` (380×460) | `ReminderCollage` | Watch daily-check-in mockup |

Every board asset is now in the app — no remaining placeholders. Swap any image
by replacing the file inside its `.imageset`.

## SF Symbols used as close matches
Flame, shields, gems→`diamond.fill`, gift, gear, clock, drops, chevrons,
`exclamationmark.octagon` (panic), `rosette` (badges), `trophy.fill` (levels),
`laurel.leading`, `light.beacon.max.fill` (siren), `faceid`, `applewatch`,
`checkmark.shield.fill`. These render acceptably and need no replacement, but can
be swapped for custom glyphs if exact parity is required.

## Notes
- The app is **dark-only** (every screenshot is dark); `UIUserInterfaceStyle` is
  forced to Dark. `AppearanceView` shows Light/System as "Soon".
- In-app copy is kept verbatim as **"No Nut"** (the product name shown in the
  screenshots). The Xcode project / bundle is named **Rewire** per project setup.
