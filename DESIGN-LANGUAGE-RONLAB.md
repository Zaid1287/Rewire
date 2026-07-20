# Rewire Design Language — "RonLab Glass"

Source: RonDesignLab (dribbble.com/RonDesignLab, @rondesignlab), used with the designer's
permission (keep the DM screenshot archived). Extracted from 17 reference shots across four
concepts: patient records (dark/ember), padel strike analysis (dark/green), stress-relief
wearable (light/fog blue), and glucose widgets (vivid gradient tiles).

The goal of this file: any screen built strictly from these tokens and recipes should be
mistakable for a RonDesignLab shot.

---

## 1. The essence (why their shots feel expensive)

Five things carry ~90% of the look. Get these right before any component work:

1. **The background is the emotion.** Never a flat color. Always a full-bleed, blurred,
   cinematic photograph — a human silhouette, motion blur, fog — monochrome-tinted to the
   screen's emotional state (ember red = critical/urge, forest green = performance, fog
   blue = calm, near-black = neutral). UI floats *on top of a scene*, it is never "a screen".
2. **Real frosted glass, two weights.** Smoked glass on dark scenes, milk glass on light
   scenes. Heavy backdrop blur, faint tint lifted from the scene, hairline light border.
   The background visibly bleeds *through* every card.
3. **One accent per screen, semantic only.** Chrome is 100% neutral (white/grey). Color
   appears only on data: red = current/critical, green = good/potential, yellow = mid.
   Usually as a tiny 6–8px dot or a single colored value.
4. **Geometric rounded type, huge ultralight numerals.** Wide, round, airy letterforms.
   Hero stats are enormous and thin, with the unit tucked beside them at low opacity.
5. **Instrument-panel data-viz.** No standard charts. Morse-dash trend lines, tick-mark
   rulers and dials, dot-matrix numerals, arc gauges. Everything looks like a precision
   instrument, not analytics software.

---

## 2. Art direction — backgrounds

Every screen is a "scene". Rules:

- Full-bleed photo or gradient-mesh, always defocused (gaussian 20–60px equivalent) or
  motion-blurred. Subject: human silhouette (back-lit, anonymous), motion trail, or fog.
  Never a sharp photo, never a face with readable identity.
- Monochrome tint the photo toward the screen's state color. Reference tints:
  - **Ember** (critical / panic / relapse risk): near-black `#0B0708` with red-orange
    glow fields `#C2402A → #7A1F12`; grain overlay ~4%.
  - **Forest** (performance / progress): deep greens `#2E4A2A → #0F1A0E`, horizontal
    motion blur.
  - **Fog** (calm / recovery / sleep): milky blue-grey `#C6D2DC → #9FB3C4`, soft window
    light, 2% grain.
  - **Void** (neutral home): `#0A0A0B` with faint dot-grid texture (1px dots, 24px pitch,
    white 4%) and a single soft colored glow behind the primary card.
- One light source. Glows are radial, soft (blur ≥ 80px), and sit *behind* the glass so
  cards pick them up.
- Film grain 2–4% over the whole scene kills the "AI gradient" look.

SwiftUI: background = `Image` (or `MeshGradient` for Void) + `.blur` + tint
`Color.overlay(blendMode: .multiply)` + grain `Image` at `.opacity(0.03)`, all in a
`ZStack` behind a `ScrollView`.

---

## 3. Color tokens

### Neutrals
| Token | Hex | Use |
|---|---|---|
| `void` | `#0A0A0B` | dark scene base |
| `carbon` | `#161618` | opaque cards on dark (tab bar wells, dropdown pills) |
| `smoke` | `#FFFFFF` @ 6% | smoked-glass fill tint |
| `milk` | `#EDF1F4` @ 70% | milk-glass fill tint (light scenes) |
| `textHi` | `#F6F7F8` | primary text on dark |
| `textLo` | `#FFFFFF` @ 52% | labels, captions on dark |
| `inkHi` | `#1C2226` | primary text on light |
| `inkLo` | `#1C2226` @ 55% | labels on light |

### Semantic accents (data only — never chrome)
| Token | Hex | Use |
|---|---|---|
| `critical` | `#F5504E` | current/bad values, alert dot, critical status |
| `good` | `#3FE06C` | potential/good values, target markers |
| `mid` | `#D8E14C` | middle state, yellow dot |
| `alertBadge` | `#E8352E` | notification badge only |

### Widget-tile gradients (vivid stat tiles, glucose-style)
Each tile = one hue family, radial gradient, darker vignette at center-bottom, light at top:
| Tile | Gradient |
|---|---|
| coral | `#E9836F → #B54468` |
| sage | `#93B29B → #46605279` (deep green-grey vignette) |
| pink | `#F0A3CF → #C4589E` |
| cobalt | `#4A63E8 → #1D2FA8` |
| rust | `#CE6A33 → #A33E1B` (with off-hue blue glow blob allowed) |

Rule: vivid tiles appear only in widget-grid contexts (glance dashboards), max 5 hues on
screen, text stays white, values huge.

---

## 4. Typography

Family: **Urbanist** — CONFIRMED: RonDesignLab's own brand slide names it. Google Fonts,
SIL OFL, free to bundle. Hero numerals use the same family at Thin/ExtraLight (not SF).
Fallback only if Urbanist unavailable: SF Pro Rounded.

Their brand-slide palette (ground truth): `#020202`, `#B3B3B3`, `#D5D1D1`, `#871A11`
(brick red), `#0A0A36` (midnight navy).

Scale (pt, iOS):
| Role | Spec | Notes |
|---|---|---|
| Hero numeral | 76–96 / Ultralight (SF Pro, not Rounded) | e.g. `32`, `88`, `04:00`; tracking −2% |
| Hero unit | 24 / Regular @ 35% opacity | baseline-aligned suffix: `LVL`, `SCR`, `kg` |
| Screen title | 22 / Medium | rare — most screens have no title |
| Card title | 19 / Regular | "Patient Profile", "Strike Analysis" |
| Value | 17 / Regular | white; colored only if semantic |
| Label | 15 / Regular @ 52% | always ends with `:` in label:value rows |
| Caption | 13 / Regular @ 45% | helper text, e.g. timer guidance |

Patterns:
- **Label:value everywhere.** Muted label with colon, bright value: `Pace:  74 km/h` —
  value colored, unit small at 50%.
- Numerals: prefer tabular lining for anything that ticks.
- No bold headlines. Weight range Ultralight–Medium only. Hierarchy comes from size and
  opacity, never weight.

---

## 5. Glass recipes

### Smoked glass (dark scenes)
```swift
RoundedRectangle(cornerRadius: 32, style: .continuous)
    .fill(.ultraThinMaterial)                       // backdrop blur
    .environment(\.colorScheme, .dark)
    .overlay(Color.white.opacity(0.06))             // smoke tint
    .overlay(                                       // hairline light edge
        RoundedRectangle(cornerRadius: 32, style: .continuous)
            .strokeBorder(
                LinearGradient(colors: [.white.opacity(0.22), .white.opacity(0.03)],
                               startPoint: .topLeading, endPoint: .bottomTrailing),
                lineWidth: 1)
    )
    .shadow(color: .black.opacity(0.35), radius: 40, y: 20)
```

### Milk glass (light scenes)
Same shape; fill `.thinMaterial` in light scheme + `Color(hex:"EDF1F4").opacity(0.55)`
overlay; border white 45%→10%; shadow black 12%, radius 50, y 24.

### Tinted glass (state bleed)
Smoked glass + a radial `critical`/`good` glow at 12–18% opacity placed in the card's
`background` — this reproduces the red-flushed "Patient Profile" card. The tint comes
from a glow *behind* the glass, never from tinting the fill itself.

Radii: cards 32, wide pills/dropdown rows capsule, tab buttons 26 (squircle,
`.continuous`), small thumbnails 12. All corners `.continuous`.

---

## 6. Layout & spacing

- Screen margins 20. Card internal padding 24. Gap between stacked cards 12.
- Grid: single column of stacked cards; 2-up grid for stat/media cards; widget grid 2-col
  with the lead tile full-width.
- Card anatomy: title top-left · action top-right (chevron `⌄`/`⌃` for collapse, or `↗`
  in a 34pt circle for "open") · content below with 16–20 vertical rhythm.
- Hero stat block: numeral top-left of card, tiny delta indicators top-right
  (pie-slice dot + `+2` / `−5` stacked).
- Comparison layout: two label:value columns, `→` arrow centered between, left column =
  current (red values), right = potential (green values).
- Density is LOW. One idea per card. If a card needs a scrollbar, split it.

---

## 7. Components

**Dropdown pill row** — capsule, `carbon` fill (opaque, not glass), 56pt tall,
`Label: Value` (label 52%, value 100%), chevron right. Stack multiple; expanded one turns
its chevron up and reveals a glass card below.

**Tab bar / control dock** — row of 64×58 squircle buttons docked bottom, 8 gap.
Inactive: `carbon` glass, 1.5px stroke white line icon. Active: **white fill, black
glyph** — the active glyph is a unique organic 3-dot cluster mark (brand mark), not the
same icon inverted. Dock sits on a glass shelf that overlaps content.

**Stat card (media)** — glass card, title + date top, `↗` circle top-right, fanned
thumbnail stack bottom-left peeking over card edge, `label: value` count bottom.

**Morse trend line** — weight/history viz: single row of rounded dashes+dots, varying
lengths (2–40px), 3px tall, white; older data fades right to 25%. Not a sparkline — a
rhythm strip.

**Dot-matrix numeral** — LED-style number made of 2px dots inside a thin 1px circle,
with a small colored squiggle accent on the ring. For secondary readouts.

**Tick ruler slider** — track 4px with segment marks, active segment = green rounded
rect; below it a full-width tick ruler (1px ticks, 8px pitch, taller every 5th); active
region ticks tinted green. Current value floats above in green; origin value grey left.

**Tick dial (intensity)** — circular ruler of radial ticks; value bubble (dark glass
circle, 44pt numeral) rides the dial; neighbor values ghosted at 20% on the arc; `«` `»`
step chevrons inside; transport row below (three 72pt circle glass buttons, 1.5px icons).

**Arc gauge** — semicircular tick arc, needle dot on arc, endpoint labels at 45% ("Stress"
/ "Relax"), white heart/status circle at center-bottom.

**Timeline arc** — shallow arc with time labels along it (9PM…9PM), vertical bar
histogram riding the top of the arc, position dot on the line.

**Status dot legend** — 8px colored dot + label ("● Critical") inline with values;
stacked mini-rows of `value ● ———` for multi-metric compare.

**Big glass buttons** — `−1 min` / `+1 min`: large 120×88 glass rounded rects, quiet
label, no border emphasis. Actions look like calm surfaces, not buttons.

**Toggle pill** — Basic/Premium: capsule container, active half = white capsule w/ dark
text, inactive = transparent w/ white text.

**Organic blob cluster (mood picker)** — soft-edged rounded-blob tiles (not rects) in a
honeycomb-ish cluster, each = icon + label, selected blob glows brighter/whiter. Blobs are
milk glass over the scene.

---

## 8. Iconography

- 1.5px stroke, rounded caps/joins, geometric, minimal detail, white (or black on white).
- 24pt optical size in 56–64pt containers.
- Sources: SF Symbols Ultralight/Thin weight covers most; custom-draw the brand 3-dot
  cluster and any instrument glyphs.
- Never filled icons except inside the active white tab button.

---

## 9. Motion

- Slow and diffused. Springs: response 0.55–0.7, damping 0.85–0.9. Nothing snappy.
- Glows breathe (opacity 0.8↔1.0, 4s ease-in-out loop) on critical states.
- Card expand/collapse: height + chevron rotate, background glow cross-fades.
- Dial/slider: tick haptics (`.selection`) per detent; value bubble follows finger with
  slight lag (interpolating spring).
- Numerals roll with `.contentTransition(.numericText())`.
- Background scenes may drift (slow 1.03 scale over 20s, ping-pong) — barely perceptible.

---

## 10. SwiftUI implementation map (Rewire)

| This file | Rewire target |
|---|---|
| Scene backgrounds | new `SceneBackground` view; states: `.void/.ember/.forest/.fog` → replaces flat bg in `Theme.swift` |
| Glass recipes | extend `DesignSystem/Theme.swift` with `smokedGlass()` / `milkGlass()` view modifiers |
| Color tokens | `Color+Theme.swift` — replace current palette with §3 tables |
| Type scale | `Theme.swift` font tokens; bundle Urbanist (Variable), Thin for numerals |
| Tab dock | `ToolkitView`/root tab bar rebuild |
| Tick dial | Panic sheet intensity → `PanicSheet.swift` |
| Morse trend | streak history strip (`ChallengeTimeline.swift`) |
| Arc gauge | urge/stress meter on Home |
| Ember scene | panic + relapse flows |
| Fog scene | recovery/breathing flows |
| Widget tiles | stats dashboard glance grid |

Font licensing: Urbanist = SIL OFL (Google Fonts), free, bundleable — no purchase needed.

---

## 11. Do / Don't (fidelity guards)

**Do**
- Blur the background until nothing in it is readable.
- Keep chrome monochrome; let only data carry color.
- One hero number per screen, enormous and thin.
- Add 2–4% grain to every scene.
- Use ticks/dashes/dots for every metric viz.

**Don't**
- No flat solid backgrounds. No sharp photos.
- No bold text, no filled chips, no borders heavier than 1px.
- No standard line/bar charts, no progress rings with fat strokes.
- No more than one accent hue per screen (widget grid excepted).
- No pure black `#000` and no pure white cards on dark scenes — always glass.
