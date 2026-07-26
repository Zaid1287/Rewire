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
| **Edit / backdate streak start** — set the start to any exact past date & time, with a live preview of the resulting streak | "won't let me change my start day and time"; "just a counter and being able to adjust it for a date in the past"; "if you relapse but forgot to adjust it, you can only reset completely" |   | 🟡 |
| **Home & Lock Screen widget** — streak on the home/lock screen | 6+ 5★ reviews rave about the competitor's widget ("I keep looking at it and feeling proud"; "see my progress every time I see my Lock Screen"). Rewire had none. Pure strength-cluster demand + a daily retention touchpoint. | [#5](https://github.com/Zaid1287/Rewire/pull/5) | 🟢 merged → TestFlight build 4 |

**Already solved (no work needed):** browsing past journal / daily entries — the competitor's "no way to view daily journal entries" is already handled by Rewire's Statistics → Daily reports list.

**Deferred (needs a backend, same as the feedback system):** cross-device sync / account (14 mentions).

---

## Cluster: Personalized Motivation & Reminders
**Type:** Strength — second-highest volume in the dataset (124 mentions, 11.9% of reviews, 4.53 avg, 75% 5★, 5.6% 1–2★). The sheet's own read: *"Strength — customers love this job. Protect."* Job: deepen what fans already love.
**Loudest praise, in a reviewer's own words:** *"I particularly like that you can put in your own motivations and your phone will randomly give them as notifications throughout the day keeping you in this conscious mindset."*

| Solution | Why (demand) | PR | Status |
|---|---|---|---|
| **Motivation reminders** — the user's own "why I quit" notes pushed back at them 1–5× a day at unpredictable times inside a 9:00–21:00 window | The quote above is the single most specific praise in the cluster. Reinforced by "with the daily reminders it makes my urges less and less stronger each day"; "I love the daily reminders and goal setting. It keeps me motivated"; "the daily motivation notifications"; "erinnert einen oft daran wofür man das ganze macht" (reminds you often what you're doing it all for). | — | ⚪ built, not yet raised |

**The gap it closes:** Rewire already stored motivations (Toolkit → My Motivations) and already had a notification pipeline — but the two were never connected. The single daily reminder sent the same fixed string forever ("Stay on track / Check in with your streak today"), and the motivations list was a screen nobody reopened. The competitor's most-praised mechanic was the wiring between them.

**Design calls:**
- **Their words, verbatim.** The notification body is the user's own motivation text; the title is a fixed "Remember why". No generic quote packs — the differentiated thing is that it's *theirs*.
- **Unpredictable, not random-feeling-random.** Slots are evenly spaced across the window then jittered, and the rotation starts at a random offset so the same "why" isn't forever the 9am one. Clockwork is what people tune out.
- **Never overnight.** Fixed 9:00–21:00 window, stated in the UI.
- **Off by default, and impossible to enable empty.** The toggle is disabled until at least one motivation exists — otherwise it would silently schedule nothing and look broken. Deleting the last motivation cancels the batch but leaves the toggle on, so it resumes the moment a new one is written.
- **Independent of the daily check-in reminder.** Separate toggle, separate identifiers — turning one off never silences the other.

**Against a bug the competitor actually shipped:** one of their reviewers wrote *"My remember now just says reminder body 1,2 etc. please fix this."* — placeholder strings reaching production notifications. The scheduler's pure planner is split out from the `UNUserNotificationCenter` I/O so a debug-launch self-check can assert every body is a real, non-empty user motivation, that nothing fires outside the window or in the past, that ids are unique and cancellable, and that the batch stays under the iOS 64-pending cap.

**Verified in the Simulator:** self-check asserts pass on launch, the section gates correctly on an empty motivations list, the toggle requests permission and persists, the 1–5 stepper clamps and persists, and state survives reinstall. Notification *delivery* itself is Apple's local-notification path — no physical-device caveat here, unlike the blocker work.

---

## Cluster: Paywall / Pricing & Monetization
**Type:** Kill-zone — the biggest churn driver across every competitor (No Nut 53 mentions, 2.4 avg; QUITTR 38% of reviews at 1.2 avg; Seed 23% at 1.3; Brainbuddy 15% at 1.6). Job: don't become them.
**Audited 2026-07-26, nothing shipped yet.** Full work order: [PAYWALL-CLUSTER.md](PAYWALL-CLUSTER.md).

| Solution | Why (demand) | PR | Status |
|---|---|---|---|
| **Real StoreKit restore** — "Restore Purchase" currently grants premium to anyone who taps it, no receipt check | Free-trial / billing-trap theme, 3–5% of competitor reviews at 1.3–1.6 avg; Seed's broken restore is a named 1★ cause | — | ⚪ |
| **One trial policy, stated once** — the sheet says "no auto-charging trial", onboarding sells a 7-day one; post-trial price never shown on the CTA | Same billing-trap theme; also an Apple disclosure requirement | — | ⚪ |
| **Drop the fake urgency** — a 6-min "special offer" clock paints a red notification dot on the gift icon, and the gift opens the gem chest, not an offer | "Paywall aggression" theme; artificial scarcity is the pattern the 1★ reviews punish | — | ⚪ |
| **Un-monetize the crisis** — surviving an urge pays free users 25 gems vs premium's 150, plus a "See Premium" card in the post-crisis debrief | Reddit gap table names "upsell inside crisis moment" as a risk with "remove paywall from the panic path" as the action | — | ⚪ |
| **Drop unsubstantiated claims** — "#1 Quit Porn Addiction App" plus fabricated testimonials on the onboarding paywall | App Store 1.4.1 / 2.3.1 / 3.1.2 exposure; not demand-driven, submission-driven | — | ⚪ |
| **Make the paywall true** — no feature in the app is actually gated, yet both paywalls sell eight free features as premium (including the blocker) | This *is* the parked "blocker-behind-paywall" item (28 reviews) — it was a symptom, not a copy fix | — | 🔴 blocked on the free/premium decision |

**Decision needed from the lead:** what Premium actually is — supporter tier (everything stays free), free core + paid depth, or real gates matching today's claims. Trade-offs in [PAYWALL-CLUSTER.md](PAYWALL-CLUSTER.md#open-decision-what-premium-actually-is). The first five rows above are independent of that call and could ship as one PR.

**Also unresolved:** prices are hardcoded ₹ with no StoreKit products behind them, so every non-India storefront sees rupees.

---

## Cross-cutting: not a cluster, flagged for the lead
- **Feedback-to-Slack system** (lead request): needs a backend — a Slack token can't ship in the app, replies arrive by webhook, and the user↔thread map must persist server-side. Also conflicts with the current privacy policy + App Store data label, and feedback in a recovery app is GDPR special-category data. Recommend scoping as its own project with the policy/manifest updates in the same release.
