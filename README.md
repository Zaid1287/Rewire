# Rewire (No Nut) — SwiftUI recreation

A production-quality SwiftUI recreation of the "No Nut" quit-porn-addiction app,
rebuilt from 41 designer screenshots. Dark-only, iOS 17+, MVVM, component-based,
Swift Package Manager only.

## Open & run
```
open Rewire.xcodeproj
```
Select the **Rewire** scheme → an iPhone simulator → Run. Deployment target
iOS 17.0. No third-party dependencies. The project uses Xcode's file-system
synchronized groups, so every file under `Rewire/` is picked up automatically.

## What's built (all 40 screens)
- **Onboarding funnel** — hero carousel, social proof, 4-question quiz, test-
  completed loader, 80% score result, without/with comparison, benefits, more
  testimonials, reminders permission, welcome splash.
- **Home** — live streak timer, goal progress, shortcuts, weekly strip, plan
  upsell, floating special-offer countdown. Sub-flows: Set Goal, Add Days,
  My Streak (calendar), Relapse flow, Daily Report flow, Panic sheet, Reward
  box, Weekly Challenge.
- **Quit Porn** — feature hub (recommended / boost / willpower / privacy).
- **Recovery** — recovery ring, Superpowers, Badges, Levels.
- **History** — streak list, Statistics, streak detail, Add Event.
- **Settings** — appearance, app icon, support, about, plan.

## Architecture
```
Rewire/
├─ App/            entry point, root gate, tab shell
├─ DesignSystem/   Color, Typography, Spacing, Radius, Shadow tokens
├─ Components/     Buttons, Cards, Quiz, Navigation, Calendar, Overlays, Misc
├─ Features/       Onboarding, Home, QuitPorn, Recovery, History, Settings
├─ Models/         value types + SampleData (all copy transcribed from shots)
├─ Stores/         AppState, StreakStore, GemStore (@Observable, injected via .environment)
├─ Utilities/      formatters, haptics, view helpers
└─ Resources/      Assets.xcassets, PLACEHOLDERS.md
```
- State: `@Observable` stores injected through the SwiftUI environment.
- All colors/spacing/type/radius come from `Theme.*` tokens — no magic numbers.
- Un-recreatable art (photos, cartoons, device mockups) is a documented
  placeholder — see [PLACEHOLDERS.md](Rewire/Resources/PLACEHOLDERS.md).

## Notes
- In-app text is verbatim **"No Nut"** (as in the screenshots); the project /
  bundle id is **Rewire** / `com.rewire.app`.
- Dark mode only, matching every screenshot.
