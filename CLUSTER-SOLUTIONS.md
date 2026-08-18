# Rewire — Cluster Solutions Log

_What we shipped per review cluster, and the demand behind it. Forward-ready for the lead._
_Source: competitor (No Nut) review analysis — 1,040 reviews across 14 clusters. Demand counts are reviews explicitly asking; cluster totals in parentheses._

**Legend for status:** 🟢 merged · 🟡 PR open, awaiting review · 🔴 blocked · ⚪ proposed, not started
**Shared caveat:** all blocker/Screen-Time work is verified in the Simulator via a debug fake; the real Screen Time behaviour needs one pass on a physical iPhone before any of it is proven. Flagged per item.

---

## Cluster: Accountability / Self-Discipline
**Type:** Strength (61 mentions, 4.52 avg, 3% 1–2★). Job: deepen what fans already love.
**Loudest ask:** the blocker is too easy to switch off in a weak moment.

| Solution | Why (demand) | PR | Status |
|---|---|---|---|
| **Commitment lock** — lock the blocker for a chosen window (1 day–1 month); turning it off early costs a 30-min cooling-off wait, not a tap | "It is tempting for me to go back in and delete or toggle off blocker status"; "it could be stricter… real accountability would make the streaks meaningful". Two reviewers wrote near-identical specs and both said it was the difference from 5★. | [#2](https://github.com/Zaid1287/Rewire/pull/2) | 🟡 |

**Design call:** they asked for a *password*; we built a *time delay*. Face ID proves you're the device owner — exactly the person trying to bypass it. What defeats an urge is outlasting it (the app's own copy says urges pass by min 10–15). Honest about the ceiling: the UI states it can't stop someone disabling Screen Time in iOS Settings.

---

## Cluster: Website / Content Blocker
**Type:** Underserved — highest rating-drag in the whole dataset (119 mentions, 3.41 avg, 29% 1–2★, ~111 star-points pulled off the store rating). This is the single biggest lever.
**Key finding:** the blocker was silently broken in *our own* code — it shielded only hand-picked apps/sites and never turned on Apple's web filter, so it could report "on" and block nothing. Same failure that sank the competitor.

| Solution | Why (demand) | PR | Status |
|---|---|---|---|
| **Apple web filter** — OS-level adult-content filtering | 33 reviews on browser coverage (21 explicitly "Safari-only — just download Chrome and bypass"); 17 on "doesn't block / bypassable" ("more holes than Swiss cheese") | [#3](https://github.com/Zaid1287/Rewire/pull/3) | 🟡 |
| **Site exceptions (escape valve)** — allow a wrongly-blocked site without disarming the whole blocker | ~6 reviews on over-blocking (Forbes, government, ministry sites). Their reviewers describe over-block → user disables → stays off forever. | [#3](https://github.com/Zaid1287/Rewire/pull/3) | 🟡 |
| **Custom denylist** — block sites Apple's list misses | "comic and AI sites you can still access" | [#3](https://github.com/Zaid1287/Rewire/pull/3) | 🟡 |

**Why it works where the competitor failed:** filtering at the OS level covers Chrome/Brave/Firefox/in-app browsers (not one Safari extension), has no extension to switch off, and uses Apple's curated list instead of keyword-guessing. Exceptions inherit the commitment lock's rule — allowing a site is a *weakening* edit, refused while a commitment runs, so the allow-list can't become the bypass the competitor shipped.

**Paused** at the lead's direction to prioritise Progress Tracking. The remaining sub-cause — **blocker-behind-paywall** (28 reviews) — is now **resolved**: the free/premium decision landed on 2026-08-18 (free core, paid depth), the blocker is free forever by policy, and the paywall copy that advertised it as premium is gone. See the Paywall / Pricing cluster below.

---

## Cluster: Progress Tracking / Streak Counter
**Type:** Strength — highest volume in the dataset (135 mentions, 4.52 avg, lifts the rating ~23 star-points). Job: protect and extend.

| Solution | Why (demand) | PR | Status |
|---|---|---|---|
| **Edit / backdate streak start** — set the start to any exact past date & time, with a live preview of the resulting streak | "won't let me change my start day and time"; "just a counter and being able to adjust it for a date in the past"; "if you relapse but forgot to adjust it, you can only reset completely" |   | 🟡 |
| **Home & Lock Screen widget** — streak on the home/lock screen | 6+ 5★ reviews rave about the competitor's widget ("I keep looking at it and feeling proud"; "see my progress every time I see my Lock Screen"). Rewire had none. Pure strength-cluster demand + a daily retention touchpoint. | [#5](https://github.com/Zaid1287/Rewire/pull/5) | 🟢 merged → TestFlight build 4 |

**Already solved (no work needed):** browsing past journal / daily entries — the competitor's "no way to view daily journal entries" is already handled by Rewire's Statistics → Daily reports list.

**Deferred (needs a backend, same as the feedback system):** cross-device sync / account (14 mentions).

---

## Cluster: Paywall / Pricing & Monetization
**Type:** Underserved — the single biggest churn driver across every competitor. No Nut: 53 mentions (5%), 2.4★, ~138 star-points of drag. QUITTR: **298 (38%), 1.2★**. Seed: 101 (23%), 1.3★. Brainbuddy: 162 (15%), 1.6★.
**Loudest ask:** stop the trap. Paywalled crisis tools, billing surprises, restore that doesn't work, fake urgency.

| Solution | Why (demand) | PR | Status |
|---|---|---|---|
| **Restore Purchase actually restores** — real `AppStore.sync()` + entitlement re-read, honest "Nothing to restore" | Broken/ignored restore is a recurring 1★ theme across all three competitors. Ours was worse: it granted premium to anyone who tapped it | [#9](https://github.com/Zaid1287/Rewire/pull/9) → [#11](https://github.com/Zaid1287/Rewire/pull/11) | 🟢 |
| **No fake urgency** — the 6-minute offer clock and the misleading "reward waiting" red dot deleted | Artificial scarcity is the pattern the competitor reviews punish hardest | [#10](https://github.com/Zaid1287/Rewire/pull/10) | 🟢 |
| **Nothing fabricated** — "#1 Quit Porn App", invented testimonials, and bro-science benefits cut | *"right after setting it all up it turns out to be a subscription based app"*; App Store 1.4.1 / 2.3.1 exposure | [#9](https://github.com/Zaid1287/Rewire/pull/9), [#10](https://github.com/Zaid1287/Rewire/pull/10) | 🟢 |
| **Crisis is never monetized** — no reward asymmetry, no upsell on the riding screen, identical copy on both tiers | *"The apps I keep on getting are paywall"* — r/QuitPornForever. Reddit names "upsell inside crisis moment" as a specific risk | [#8](https://github.com/Zaid1287/Rewire/pull/8), [#11](https://github.com/Zaid1287/Rewire/pull/11) | 🟢 |
| **Real StoreKit 2 + real localized prices** — entitlement is the source of truth; hardcoded ₹ deleted | Every storefront outside India was shown rupees. Premium was a boolean anyone could flip | [#11](https://github.com/Zaid1287/Rewire/pull/11) | 🟢 |
| **No free trial** — monthly is the trial; `price → renewal period` next to every CTA | Free-trial / billing-trap is its own theme at 3–5% of reviews across all three competitors, 1.3–1.6★ | [#11](https://github.com/Zaid1287/Rewire/pull/11) | 🟢 |
| **The four Premium gates** — stats past 30 days, slip-pattern insights, 21-day plan, appearance tracker | Closes the last gap: the paywall now describes depth that isn't withheld yet | | ⚪ next |

**Design call — what Premium is (decided 2026-08-18): free core, paid depth.** Everything that gets someone through a bad night is free forever — Panic/Urge SOS, breathing, the streak and its backdate, the Screen Time blocker, daily check-in, unlimited slip logs. Premium buys the analysis that only exists once there's history to analyse. Two options were rejected: a *supporter tier* (all tools free, pay to support) gives up the revenue that funds the backend the buddy/sync reviews ask for; *keeping the old claims and gating them* would have locked the blocker and the crisis tools — precisely the pattern behind QUITTR's 298 complaints at 1.2★. Full reasoning in `PAYWALL-CLUSTER.md`.

**Honest about the ceiling:** the paywall now names four depth features that are not actually withheld from free users yet — the gates are the next card, and no build should go to external testers until both have shipped. Real products also don't exist in App Store Connect yet, so no purchase can complete outside the local test configuration.

---

## Cross-cutting: not a cluster, flagged for the lead
- **Feedback-to-Slack system** (lead request): needs a backend — a Slack token can't ship in the app, replies arrive by webhook, and the user↔thread map must persist server-side. Also conflicts with the current privacy policy + App Store data label, and feedback in a recovery app is GDPR special-category data. Recommend scoping as its own project with the policy/manifest updates in the same release.
