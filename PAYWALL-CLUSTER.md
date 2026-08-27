# Cluster: Paywall / Pricing & Monetization — audit & backlog

_Audited 2026-07-26. Updated 2026-08-18 — findings #2, #4, #5 and #6 are **shipped and merged**
(PRs [#8](https://github.com/Zaid1287/Rewire/pull/8), [#9](https://github.com/Zaid1287/Rewire/pull/9),
[#10](https://github.com/Zaid1287/Rewire/pull/10)). #1 and #3 were blocked on the "what is Premium"
decision — **that decision is now made, see [The decision](#the-decision-2026-08-18--free-core-paid-depth)**._
_Cluster picked as the next lever after Progress Tracking shipped in TestFlight build 4._

---

## Why this cluster is next

| Signal | Number |
|---|---|
| No Nut reviews mentioning paywall/pricing anger | **53 (5%), avg 2.4★** — ~138 star-points of drag |
| QUITTR | **298 (38%), avg 1.2★** — their single biggest churn driver |
| Seed | **101 (23%), avg 1.3★** |
| Brainbuddy | **162 (15%), avg 1.6★** |
| Free-trial / billing trap (separate theme) | 3–5% of reviews across all three competitors, 1.3–1.6★ |

Source: [research/reviews/theme-analysis.md](research/reviews/theme-analysis.md). Its own headline:

> Paywall aggression and billing traps are the single biggest churn driver across QUITTR, Brainbuddy, and Seed — it dwarfs every other complaint. **Rewire's biggest competitive lever is a paywall that doesn't feel like a trap.**

Reddit corroborates ([research/reddit/reddit-insights.md](research/reddit/reddit-insights.md)):
- *"The apps I keep on getting are paywall."* — r/QuitPornForever, asking for a non-paywalled rec
- Brainbuddy: *"right after setting it all up it turns out to be a subscription based app."*
- Its gap table already names three of the fixes below: no paywall in Panic, no post-purchase upsell, working restore + honest trial copy.

Also unblocks the item parked in [CLUSTER-SOLUTIONS.md](CLUSTER-SOLUTIONS.md) under Website/Content Blocker — *"blocker-behind-paywall (28 reviews) — the blocker is already free in Rewire; the real issue is the paywall copy advertising it as premium."* That turned out to be a symptom of finding #1 below, not a one-line copy fix.

---

## Findings

Ordered by severity. Line numbers are as of commit `aadf71f`.

### 1. 🔴 Nothing is actually gated, but both paywalls sell gated features

There is **not a single feature lock in the codebase**. Every `isPremium` read in `Rewire/` is
cosmetic — it changes copy, gem rates, upsell visibility, or a badge. Full list:

| Site | What `isPremium` actually does |
|---|---|
| `SettingsView.swift:302-311` | Row title/subtitle wording |
| `PaywallSheet.swift:18-25` | Which plans to show (upgrade filtering) |
| `HomeView.swift:101,120` | Whether to start the offer timer / show the red dot |
| `PanicSheet.swift:139` | Gem reward rate (see finding #5) |
| `PanicSheet.swift:189,203,322` | Copy variants + the upsell card |
| `BadgesView.swift:38` | Whether to show an upsell |
| `BadgeProgress.swift:33` | "Premium Member" / "Mentor Owner" badge eligibility |

Meanwhile the two paywalls advertise as premium:

- [`PaywallSheet.swift:27-32`](Rewire/Features/Home/PaywallSheet.swift:27) — "Unlimited panic & breathing tools", "Full history, stats & recovery", **"Website blocker across every browser"**, "No ads. No account. Local & private."
- [`OnboardingPaywallView.swift:147-157`](Rewire/Features/Onboarding/OnboardingPaywallView.swift:147) — "Urge-wave Panic mode", "Slip-pattern insights", "21-day Personal Plan", "Appearance Tracker"

All eight are free right now. A user pays, gets nothing new, and writes the 1★ review this whole
cluster is about. It is also an App Store 2.3.1 (accurate metadata) / 3.1.2 exposure.

**Blocked on a decision — see [Open decision](#open-decision-what-premium-actually-is) below. Everything else in this file is packaging-independent.**

---

### 2. ✅ RESOLVED (PR #9) — Restore Purchase handed premium to anyone who tapped it

[`SettingsView.swift:115-118`](Rewire/Features/Settings/SettingsView.swift:115)

```swift
private func restorePurchase() {
    gems.unlockPremium(plan: "1 year")   // mock restore — real plan comes with StoreKit
    ...
    showRestoredAlert = true
}
```

No receipt check, no StoreKit, no failure path. Tapping "Restore Purchase" in Settings is currently
a free premium button. Ships today.

**Fix:** real `StoreKit 2` restore — `AppStore.sync()` + `Transaction.currentEntitlements`, with a
genuine "Nothing to restore" branch. Until StoreKit lands, this should at minimum not grant anything.

---

### 3. 🟠 The two paywalls contradict each other on the trial *(closed by the decision below)*

- [`PaywallSheet.swift:130`](Rewire/Features/Home/PaywallSheet.swift:130) — "No auto-charging trial · cancel anytime · restore in Settings"
- [`OnboardingPaywallView.swift:108,117,221`](Rewire/Features/Onboarding/OnboardingPaywallView.swift:108) — "Start my 7-day free trial", "✓ No payment due today · Cancel anytime", "Annual includes a 7-day free trial"

One says there is no auto-charging trial; the other sells one on the preselected annual plan. Both
ship in the same build. Whichever is true, the other is the billing-trap complaint written in advance.

Also: **the post-trial price never appears on the trial CTA.** "Start my 7-day free trial" +
"No payment due today" with no "then ₹699/year" is exactly the disclosure Apple requires and exactly
what the free-trial-trap reviews describe.

**Fix:** pick one trial policy, state it identically in both surfaces, and put
`price → renewal period → what happens at trial end` adjacent to the CTA.

---

### 4. ✅ RESOLVED (PR #10) — Fake urgency + a misleading notification badge

[`GemStore.swift:79-82`](Rewire/Stores/GemStore.swift:79)

```swift
/// Start the one-time special offer (6 minutes) if it never ran.
func startOfferIfNeeded() {
    guard offerDeadline == nil else { return }
    offerDeadline = Date().addingTimeInterval(6 * 60)
}
```

A 6-minute countdown starts on first Home visit. To its credit it never resets — but it drives
[`HomeView.swift:119-124`](Rewire/Features/Home/HomeView.swift:119), which paints a **red
notification dot on the gift icon** while the offer runs. Tapping the gift opens
[`RewardBoxView`](Rewire/Features/Home/RewardBoxView.swift) — the gem chest, which has nothing to do
with the offer. So the badge says "you have a reward waiting" and means "a paywall clock is running".

Nothing in the app ever surfaces the offer itself; there is no discounted price anywhere in
`SampleData.plans`. The countdown currently exists only to produce the red dot.

**Fix:** delete the offer clock and the dot, or make the dot mean what it looks like. Recommend
delete — artificial scarcity in a recovery app is the pattern the competitor reviews punish.

---

### 5. ✅ RESOLVED (PR #8) — The crisis moment was monetized

[`PanicSheet.swift:136-140`](Rewire/Features/Home/PanicSheet.swift:136)

```swift
/// Premium rides the wave: +10 gems per minute held, capped at the 15-min
/// wave end. Free keeps the flat reward.
private var rewardIfSafeNow: Int {
    gems.isPremium ? min(150, minutesRidden * 10) : 25
}
```

Free users get **25 gems** for surviving an urge; premium users get **up to 150** for the identical
act. Then [`PanicSheet.swift:322-339`](Rewire/Features/Home/PanicSheet.swift:322) shows a
"Go further next time — See Premium" card in the debrief, seconds after someone came out of a crisis.

The *riding* screen is already clean (someone did that pass — the comment at line 183 says "crisis
screen — no upsell, ever"), and the debrief is the least-bad place for a pitch. But the reward
asymmetry monetizes the recovery act itself, and [reddit-insights.md](research/reddit/reddit-insights.md)
lists "upsell inside crisis moment" as a named risk with "remove paywall from panic path entirely"
as the action.

**Fix:** same reward for the same act on both tiers. Move any premium mention out of the debrief, or
reduce it to a non-blocking line with no CTA.

---

### 6. ✅ RESOLVED (PR #9) — Unsubstantiated superlative + fabricated testimonials

[`OnboardingPaywallView.swift:198`](Rewire/Features/Onboarding/OnboardingPaywallView.swift:198)

```swift
Text("#1 Quit Porn Addiction App")
```

Rewire is not #1 at anything — it has not shipped. Directly under it,
`SampleData.quoteTestimonials` renders invented user quotes as social proof on a paywall page.

App Store Review 1.4.1 (physical/mental health claims), 2.3.1 (accurate metadata) and 3.1.2 exposure,
plus consumer-protection risk on fabricated endorsements in several storefronts. Run the
`greenlight` skill over this screen before any submission.

**Fix:** drop the superlative. Either remove the testimonials page or replace with real, attributed
TestFlight feedback (and label it as such).

---

## The decision (2026-08-18) — free core, paid depth

**Decided by us** (the lead funds and approves spend only; every product call is ours per
[SOP.md §1](SOP.md)). Recorded here because it ripples through the paywalls, the StoreKit work,
the badge catalog and the App Store listing.

### What Premium is

> **Everything that gets someone through a bad night is free, forever. Premium pays for depth
> over time — the analysis that only becomes possible once there's history to analyse.**

| | Free, forever — never gated, never counted | Premium — depth |
|---|---|---|
| **Crisis** | Panic / Urge SOS, 4-4-4 breathing, urge-wave timer, motivations recall | — |
| **Streak** | The streak itself, two-layer record/run, Edit Start backdate, widget, levels, badges | — |
| **Blocker** | Screen Time shield, Apple web filter, custom denylist, site exceptions, commitment lock | — |
| **Daily loop** | Daily check-in, slip log (unlimited), reminders | — |
| **Stats** | Last 30 days of history | Full history beyond 30 days, trends across it |
| **Insight** | The raw slips you logged | **Slip-pattern insights** (the fingerprint across them) |
| **Program** | — | **21-day Personal Plan** |
| **Body** | — | **Appearance Tracker** |

### Why this and not the other two options

- **vs. Supporter tier** (all tools free, pay to support): the honest-copy win is real but the
  revenue is charity-shaped, and a recovery app that can't fund its own backend can't ship the
  buddy/sync features Reddit asks loudest for. Free core already captures ~all of the anti-QUITTR
  positioning; the supporter framing gives up the revenue for a marginal honesty gain.
- **vs. keep the current claims and gate them**: those claims gate the blocker and the crisis
  tools. That is exactly the pattern behind QUITTR's 298 paywall complaints at 1.2★ and the
  28 "blocker behind paywall" reviews in our own competitor set. Non-starter.
- **Free core, paid depth passes the §0 test:** nothing a person in crisis reaches for costs money,
  so the paywall can never be in the way at the moment that matters. What's paid is the stuff
  you only want on a calm Sunday — which is also the only stuff a user can fairly judge the
  value of before paying, because they can see 30 days of it for free first.

### Consequences (each becomes work)

1. **Four gates to build** — stats > 30 days, slip-pattern insights, 21-day plan, appearance
   tracker. Nothing else in the app gets a lock. Gate = a clear, non-nagging "this is Premium"
   state with one CTA, never a hidden dead end, never a modal you can't dismiss.
2. **Both paywall benefit lists rewritten to match** — and the free things *labelled free*
   ("the blocker is free, always" is a selling point given the competitor reviews).
3. **No free trial.** Closes finding #3 in the honest direction: the contradiction was between
   "no auto-charging trial" and a 7-day trial on the annual plan, and the billing-trap reviews
   are the single loudest complaint in the whole dataset. Monthly is the trial — it's cheap, it's
   cancellable, and nothing auto-charges after a period the user has forgotten about. `price →
   renewal period` shows next to every CTA.
4. **Three products, no tiers** — monthly subscription, yearly subscription, lifetime non-consumable.
   Real StoreKit products, localized prices from the App Store (the hardcoded ₹ dies).
5. **Badge catalog:** "Premium Member" survives as an earned badge; badges tied to features that
   may never ship (Community, Mentor, Videos) are still cut separately (P1, Design track).

### Order of work

- **Card A — StoreKit 2 (Engineering, this branch):** real products + purchase + restore +
  entitlement as the single source of truth, no-trial policy stated identically in both surfaces,
  hardcoded ₹ deleted. Paywall benefit copy is trimmed to statements that are true *today*.
- **Card B — Premium gates + paywall packaging (Engineering/Marketing, next):** the four gates
  above, then the benefit lists rewritten to sell exactly what B gates. **Neither A nor B alone
  is submittable** — A without B sells depth that isn't gated, B without A can't take money.
  Both land on `dev` before any TestFlight build goes external.
