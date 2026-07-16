# Rewire — Addiction Recovery

A native SwiftUI app that helps people quit porn: streak tracking that survives
relapses, a guided panic tool for riding out urges, honest habit-building, and a
gamified recovery arc. Dark-only, iOS 17+, zero third-party UI dependencies.

Originally built as a faithful recreation of a competitor's designs, then
**redesigned end-to-end** (branch `design-refresh`) based on a research pass over
~3,300 competitor App Store reviews and ~500 Reddit posts from recovery
communities. Every major change maps to a documented churn driver in that
research.

## The redesign in one screen each

| Surface | What changed & why |
|---|---|
| **Streak model** | Two layers: *total clean days + success rate* never reset; the current run is secondary. The hard reset-to-zero was the single most-cited reason users abandon competitor apps. The morning after a slip, Home leads with "Still 47." — what survived — not a zeroed timer. |
| **Slip logging** | The punitive relapse flow (coin penalty, "do you feel regretful?") is replaced by a pattern log: when / trigger / feeling chips, an insight card ("3 of your last 4 slips were late-night"), reset on save, and undo until midnight. Research: shame framing measurably backfires. |
| **Daily check-in** | 5-step interrogation → one sheet: *Clean / I slipped*, 3 seconds total. |
| **Panic tool** | Free for every user (no upsell in a crisis — competitors get flayed for this). Premium extends it with an urge-wave visualization (~10-min curve you ride, per-minute rewards) and a post-crisis debrief — the only place premium is pitched. The breathing orb is the hero of the screen: inhale-first, soft glow, 4-4-4 pacing. |
| **Navigation** | 5 tabs → 4: Today / Progress / Toolkit / Settings. Liquid Glass floating chrome throughout (iOS 26 `glassEffect` with material fallback), and a Reddit-style collapsing dock: folds to the active-tab pill on scroll down, reopens on scroll up. |
| **Onboarding** | 10 screens → 7 + a soft multipage paywall after the score reveal: three plans (monthly / annual w/ 7-day free trial / lifetime), "no payment due today · cancel anytime" spelled out, skippable from page one, nothing gated. |
| **Honesty pass** | Every row in the app now either does something real or says "Soon". Unshipped features are never presented as working; badges are earned from real state, never free-claimed. |

## Open & run

```
open Rewire.xcodeproj
```

Select the **Rewire** scheme → any iPhone simulator → Run. Deployment target
iOS 17.0 (glass effects require an iOS 26 runtime and degrade gracefully below).
The project uses file-system synchronized groups — files under `Rewire/` are
picked up automatically. Only SPM dependency is PostHog (analytics facade,
currently disabled).

## Architecture

```
Rewire/
├─ App/            entry point, root gate (onboarding vs main), Face ID lock
├─ DesignSystem/   Theme tokens: Colors, Typography, Spacing, Radius, Shadow,
│                  Motion (animation curves), Glass (Liquid Glass + fallback)
├─ Components/     Buttons, Cards, Quiz, Navigation (glass tab dock), Overlays
├─ Features/       Onboarding (incl. paywall), Home (streak, check-in, slip log,
│                  panic), Progress, Toolkit (incl. My Shield), Settings
├─ Models/         value types + static content
├─ Stores/         AppState, StreakStore, GemStore — @Observable, injected via
│                  .environment, persisted as one JSON snapshot
└─ Utilities/      haptics, formatters, badge progress, reminders
```

- **State**: three `@Observable` stores; every mutation persists via a debounced,
  atomic, file-protected JSON snapshot. Older snapshots always decode (new
  fields are optional with defaults) — no migrations.
- **Design tokens**: all color/spacing/type/motion goes through `Theme.*`;
  no magic numbers in feature code.
- **Motion**: tokenized curves, directional step transitions, Reduce Motion
  respected everywhere (gentler, not zero).
- **Privacy**: everything stays on device. No account, no server. Analytics
  events are funnel-only — never quiz answers, slip details, or photos.

## Status

- Feature-complete for beta; on TestFlight internal testing.
- Purchases are **mocked** — StoreKit 2 + a working Restore Purchase are the
  gate before any external release (the onboarding paywall makes this urgent).
- Porn blocker / community / widgets are honest "Soon" placeholders.
