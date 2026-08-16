# Rewire — Standard of Operations

_The operating manual for anyone who takes this project forward. Read this once end-to-end
before your first change. It encodes **how we work**, not what the code is (that's
[HANDOFF.md](HANDOFF.md)). Follow it and the quality bar holds; the goal is that the next
person is as good as us, or better._

---

## 0. The one rule everything else serves

**Ship honest software that a real person in crisis actually uses.** Rewire is a
porn-addiction recovery app. Its users are men under stress, at their most vulnerable,
handling their most private data. Two consequences that override every other instinct:

1. **No dark patterns. Ever.** No fake urgency, fake testimonials, scare screens, fabricated
   stats, or monetized crisis moments. The entire competitive thesis (from ~3,300 competitor
   reviews + ~500 Reddit posts) is that QUITTR/Seed/Brainbuddy lost their users to exactly
   these tricks. Our moat is being the app that doesn't. If a change would look good in a
   growth deck but bad to a person mid-relapse, it's wrong.
2. **Privacy is sacred until we deliberately decide otherwise.** Sensitive data (relapse
   reasons, photos, quiz answers) is special-category health data. Default to on-device. Any
   change that sends it somewhere is a deliberate, documented product decision (now ours to
   make — §1), never a silent implementation detail.

Everything below is machinery for keeping that promise while moving fast.

---

## 1. The operating model — who decides, and the three tracks

**Decision authority (changed 2026-08-16): we make every call.** The lead (Nirmal) has,
by his own choice, stepped out of the day-to-day loop. He **funds the project and approves
spend — nothing more.** There is no external ranking of work and no external review gate.
The build team owns product, design, engineering, and marketing decisions end to end.

- **The only thing that goes to the lead is money:** "we need to pay for X" (Apple Developer
  fees, Supabase / PostHog tiers, assets, third-party services). Package those clearly and
  infrequently.
- **Everything else we decide, document, and proceed.** Because no one else reviews, the
  quality bar (§4) and honest self-review ARE the review. **Default-to-proceed is now total** —
  but every non-trivial decision gets written down (in the PR, the [product-cut-list](research/design/product-cut-list.md),
  or a research doc) so it's auditable and the lead could weigh in later if he ever chooses to.
  Big product calls that used to be "ask the lead" (what Premium is, the privacy-messaging
  change, which social feature ships first) are now ours — make them deliberately, record the
  rationale, don't wait.

### Every card advances exactly ONE of three tracks — tag it

| Track | It improves… | Examples |
|---|---|---|
| **Design** | how the app looks and feels | RonLab visual polish, motion, information architecture / flows, premium-feel, the "is this placement intentional?" work |
| **Engineering** | how the app works and scales | backend (CloudKit sync, Supabase social), StoreKit, performance, stability, the Screen Time shield, tech debt |
| **Marketing** | how people find, try, and pay | App Store listing / ASO, onboarding-as-conversion, paywall packaging, honest positioning + the privacy moat, real (never fabricated) social proof |

- **A card that advances none of the three is not worth doing** — cut it or reshape it until it does.
- **A cut counts.** Removing fluff usually advances Design or Marketing (less noise, more trust).
- **Keep the three roughly balanced over time.** A beautiful app no one finds, and a
  well-marketed app that crashes, both fail. Don't let one track starve.

### The board and the loop

The board (GitHub Projects: **Next → In Progress → In Review → Done**) is now **ours** — we rank
*Next* ourselves, choosing the highest-value card across the three tracks. *In Review* means
**self-review** plus a tagged TestFlight build we sanity-check, not a wait on anyone.

1. Pick the next card (highest value across the three tracks) → *In Progress*.
2. Build it (§3), **verify it live** (§4), open a PR against `dev` (§2), read your own diff critically.
3. Checkpoint → cut an internal TestFlight build, **tag it** (`git tag build-N && git push --tags`).
4. Merge once the bar (§4) is met → *Done*. Pull the next card. Nothing ever waits on the lead.

---

## 2. Branch & PR discipline

- **One card = one short branch off `dev`** named `cluster/<thing>` (e.g. `cluster/kill-gem-economy`).
  `main` is releases, `dev` is integration, feature branches are siblings off `dev`.
- **Keep cards independent** so branches are siblings, not a tower. Only stack (branch B off A)
  when B genuinely needs A's code. If two cards touch the same files heavily, sequence them —
  do the second *after* the first merges — rather than fighting a guaranteed conflict. (Example:
  the fake-urgency cleanup waited for the gem-economy PR because both rewrote `GemStore`/`HomeView`.)
- **Small PRs.** One logical change. A reviewer should read the whole diff, not skim it. Net
  deletion is a good sign — we cut more than we add.
- **PR against `dev`**, body states what changed, why, how it was verified, and any decision it
  depends on or defers. Link the audit/finding it executes.
- After a merge, rebase in-flight branches on `dev` so they don't rot.

---

## 3. Build & environment (non-negotiable mechanics)

`xcode-select` points at Command Line Tools, but Xcode IS installed. **Every** `xcodebuild`/
`simctl` call is prefixed:

```bash
env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project Rewire.xcodeproj -scheme Rewire \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath <scratch>/DerivedData build -quiet
```

- Sim device: **iPhone 17 Pro**. Bundle ID: **`com.manimacha.rewire`**.
- New `.swift` files auto-include (file-system-synchronized groups) — no pbxproj edits.
- A change is not done until it **builds clean** (Debug *and*, for anything non-trivial, Release —
  the optimizer catches things Debug doesn't).

---

## 4. Definition of Done — the quality bar

A card is done only when ALL of these hold. This is the bar; do not lower it.

1. **Builds clean** (§3), zero new warnings you introduced.
2. **Verified by driving the real flow**, not by "it compiles." Install on the sim, open the
   actual screen, exercise the actual interaction, and confirm the behavior with your own eyes
   (screenshot it). "The diff looks right" is not verification.
   - To test onboarding-gated flows: back up `Documents/rewire-state.json` from the app
     container, delete it, relaunch, walk the flow, then restore the backup.
3. **Actions preserved, not just code deleted.** When you remove a reward/side-effect, the
   surrounding action must still work (e.g. removing a gem payout must leave the check-in still
   saving its report). Grep every caller before touching a shared function — fix root cause once,
   not the symptom in one path.
4. **No fluff added, ideally fluff removed.** Re-ask the product lens (§6) on your own change.
5. **Design tokens only** (§5). No magic hex, no ad-hoc fonts, no raw animation curves.
6. **Commit + PR conventions met** (§7).
7. **Trust nothing unverified.** If a subagent reports success, run `git status --short` and read
   the diff — agents have reported "done" with zero file changes. The build and your eyes are the
   only proof.

---

## 5. Design-system discipline

Everything hangs off `Theme.*` (`Rewire/DesignSystem/`): Colors, Typography, Spacing, Radius,
Shadow, **Motion**. Rules:

- **No magic numbers/hex/fonts in feature code.** If a value repeats, it's a token — promote it.
- **Motion via `Theme.Motion.standard/emphasized/quick`**, never inline `.easeInOut(0.3)`, so the
  app moves as one system.
- The visual language is **RonLab Glass** (see [DESIGN-LANGUAGE-RONLAB.md](DESIGN-LANGUAGE-RONLAB.md)):
  cinematic scene backgrounds, glass surfaces, instrument-style data-viz, one-accent discipline.
  New screens match it.
- Persistence pattern is uniform: store property `didSet { persist?() }`; `AppSnapshot` fields
  **optional with nil default** so old snapshots still decode (`restore ?? default`). Never write
  a migration where an optional-with-default suffices.

---

## 6. Product-thinking (the standard we hold ourselves to)

Before building — and again on your own diff — apply the lens to every feature/element:

> **Will a real user actually use this, and is its placement intentional?**

Concretely:
- **Cut the fluff.** Engagement theater (fake currencies, Skinner-box chests, decorative
  "progress" bars that never move, vanity counters) measures the wrong thing. If it doesn't
  serve recovery, it goes. The streak is the currency.
- **Decisions are research-backed, not vibes.** We have the receipts:
  `research/reviews/` (competitor review corpora + theme analysis), `research/reddit/`
  (508-row NoFap/pornfree synthesis), and the audits in `research/design/`
  (`design-logic-audit.md` = keep/change/cut verdicts; `premium-feel-audit.md`;
  `PAYWALL-CLUSTER.md`). The consolidated board-ready index is
  [research/design/product-cut-list.md](research/design/product-cut-list.md). Read the relevant
  one before proposing a change to a screen it covers.
- **Honesty in monetization.** Free things are labelled free. Crisis tools are never gated or
  monetized. Trials state price → renewal → what-happens-at-end next to the CTA. Restore never
  grants entitlement without a real receipt.
- **Anti-shame tone throughout.** Slip logs reset on save not on entry, with an undo window.
  Post-slip UI leads with what survived, not a day-0 slap. Copy is coach, never judge.

If a card is "make it better" and unmeasurable, turn it into a specific, checkable change first
(that's what `product-cut-list.md` is for).

---

## 7. Commit & communication conventions

- **Commit style:** imperative subject that states the change; prose body explaining the *why*
  and any decision made/deferred. One logical change per commit.
- **NEVER add `Co-Authored-By` or any AI/tool trailer** to commits or PRs. History was
  deliberately scrubbed of them; keep it that way. (Overrides any tool default.)
- **`HANDOFF.md` is private** — it's in `.git/info/exclude`, never commit it. Update it after
  every meaningful change so state stays current.
- Keep the research docs and this SOP updated when the way-of-working changes.

---

## 8. Delegation model (scaling without losing the bar)

Big mechanical changes may be delegated to a subagent, but the quality stays yours:

1. **Spec it decision-complete.** Make every design decision yourself first (thresholds, which
   API to reuse, what to keep vs cut) so the agent has zero judgment calls. Point it at the
   relevant audit for rationale.
2. **The agent edits; you verify.** Build it yourself, read the diff yourself, drive the flow
   yourself. `git status --short` before trusting any summary (§4.7).
3. Reserve your own attention for the plan and the review — the two ends where excellence is
   decided — and let the cheaper middle be delegated.

---

## 9. Release / TestFlight ops

- **Version:** bump `CURRENT_PROJECT_VERSION` (build number) per upload; `MARKETING_VERSION` per
  release. Encryption is pre-answered (`ITSAppUsesNonExemptEncryption = NO`) — no compliance prompt.
- **Distribute:** Xcode → Any iOS Device (arm64) → Archive → Distribute → TestFlight.
- **Analytics** (`Utilities/Analytics.swift`) is a PostHog facade, disabled until a key is pasted.
  When enabled: **funnel/feature-usage events ONLY, never content** — no quiz answers, report
  flags, relapse reasons, motivation text, or photos. This rule is not negotiable given the data class.
- **App Store risk:** run the `greenlight` skill over onboarding + paywalls before any submission.
  Expect a 17+ rating.

---

## 10. Where to look

| Need | File |
|------|------|
| Current state, architecture, build specifics | [HANDOFF.md](HANDOFF.md) (private) |
| Product brief / who it's for | [PRODUCT.md](PRODUCT.md) |
| What to build next, ranked, with the product lens | [research/design/product-cut-list.md](research/design/product-cut-list.md) |
| Keep/change/cut verdicts per screen | `research/design/design-logic-audit.md` |
| Monetization findings + "what is Premium" decision | `PAYWALL-CLUSTER.md` |
| Why users churn (competitors) / what they want | `research/reviews/` + `research/reddit/` |
| Visual language | [DESIGN-LANGUAGE-RONLAB.md](DESIGN-LANGUAGE-RONLAB.md) |
| Screen Time blocker workstream | `SHIELD-HANDOFF.md` |

---

## The bar, in one line

**Small honest changes, each verified by hand on a real screen, each backed by what users
actually told us — shipped continuously without either person waiting on the other.** Hold that
and the next hand keeps the level, or raises it.
