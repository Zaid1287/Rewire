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

**Paused** at the lead's direction to prioritise Progress Tracking. Remaining sub-cause not yet addressed: **blocker-behind-paywall** (28 reviews) — but the blocker is already free in Rewire; the real issue is the paywall *copy* advertising it as premium. Proposal pending the lead's free/premium decision.

---

## Cluster: Progress Tracking / Streak Counter
**Type:** Strength — highest volume in the dataset (135 mentions, 4.52 avg, lifts the rating ~23 star-points). Job: protect and extend.

| Solution | Why (demand) | PR | Status |
|---|---|---|---|
| **Edit / backdate streak start** — set the start to any exact past date & time, with a live preview of the resulting streak | "won't let me change my start day and time"; "just a counter and being able to adjust it for a date in the past"; "if you relapse but forgot to adjust it, you can only reset completely" | [#4](https://github.com/Zaid1287/Rewire/pull/4) | 🟡 |
| **Home & Lock Screen widget** — streak on the home/lock screen | 6+ 5★ reviews rave about the competitor's widget ("I keep looking at it and feeling proud"; "see my progress every time I see my Lock Screen"). Rewire had none. Pure strength-cluster demand + a daily retention touchpoint. | [#5](https://github.com/Zaid1287/Rewire/pull/5) | 🟡 |

**Already solved (no work needed):** browsing past journal / daily entries — the competitor's "no way to view daily journal entries" is already handled by Rewire's Statistics → Daily reports list.

**Deferred (needs a backend, same as the feedback system):** cross-device sync / account (14 mentions).

---

## Cross-cutting: not a cluster, flagged for the lead
- **Feedback-to-Slack system** (lead request): needs a backend — a Slack token can't ship in the app, replies arrive by webhook, and the user↔thread map must persist server-side. Also conflicts with the current privacy policy + App Store data label, and feedback in a recovery app is GDPR special-category data. Recommend scoping as its own project with the policy/manifest updates in the same release.
