# Rewire — PRODUCT.md

## Register

product — app UI. Design serves the recovery tool; fidelity to the original screenshot set outranks novelty.

## What this is

A SwiftUI (iOS 17+) recreation of the "No Nut" porn-addiction recovery app, rebuilt pixel-faithfully from 41 designer screenshots, now wired to real state with JSON persistence. Bundle name "Rewire", in-app copy keeps the original "No Nut" branding.

## Target users

Men actively trying to quit porn — high-urgency, low-attention context. Key moments (panic button, relapse report) happen under stress; flows must be one-tap-direct, never decorative.

## Product purpose

Gamified abstinence tracking: live streak timer, goals, daily self-reports, badges/levels/gems, panic tool, community-style testimonials. Retention driven by streak pride and small rewards.

## Brand personality

Dark, calm, confident. Green = progress/success, red = danger/relapse, purple-blue gradient = premium/primary actions. Motivational but not preachy; short encouraging copy.

## Design constraints

- Dark-only. All tokens hang off `Theme.*` (Rewire/DesignSystem/) — no magic numbers, no hardcoded hex outside `Color(hex:)` token call sites already established.
- Screenshot fidelity is the north star: when the original design and a "better idea" conflict, match the screenshot unless it creates dead interaction (e.g. taps that do nothing).
- Un-recreatable photo assets documented in Rewire/Resources/PLACEHOLDERS.md; brand-motif placeholders stand in.
- Zero third-party dependencies. No StoreKit — premium is mocked.

## Anti-references

- Light-mode SaaS dashboards, cream/beige wellness apps.
- Shame-based messaging; the tone is coach, not judge.
- Decorative interactions that add taps between the user and a stress-moment tool.
