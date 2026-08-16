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
2. **Privacy is sacred until a human decides otherwise.** Sensitive data (relapse reasons,
   photos, quiz answers) is special-category health data. Default to on-device. Any change
   that sends it somewhere is a product decision for the lead, not an implementation detail.

Everything below is machinery for keeping that promise while moving fast.

---

## 1. The async workflow (how work flows)

Two people, different hours, no live syncs. The **board is the single source of truth**
(GitHub Projects, columns: **Next → In Progress → In Review → Done**).

**Ownership split — this is the whole trick:**
- The **lead owns the ORDER**: ranks the *Next* column. That's their input, on their time.
- The **builder owns the STATUS**: pulls the top card, moves it across as it progresses.

So the lead decides *what* and *in what order*; the builder handles *how* and keeps *where*
visible. Neither waits on the other.

**The loop, per card:**
1. Pull the top of *Next* → move to *In Progress* (max 1–2 at a time so the lead always
   knows exactly what you're touching).
2. Build it (§3), verify it live (§4), open a PR against `dev` (§2).
3. Cut an internal TestFlight build at a checkpoint, **tag it** (`git tag build-N && git push
   --tags`), write a one-line "what to look at" note. Move card → *In Review*.
4. **Immediately pull the next card.** A build out for review NEVER blocks the next task.
5. Lead reviews on their phone whenever, comments on the card → *Done* or back to *In Progress*.

**Two habits that make async actually work:**
- **Batch questions; default-to-proceed on reversible calls.** Never halt mid-task waiting for
  a reply. Collect open questions for one async answer; for anything reversible, decide, note
  it in the PR, and let review correct it.
- **Keep risky/controversial work OFF a build until the lead thumbs-ups the direction.** A
  one-line "yes" on the idea before you invest a day beats a "revert that" after.

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

## 6. Product-thinking (the standard the lead cares most about)

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
