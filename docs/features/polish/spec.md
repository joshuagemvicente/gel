# U9 · Polish & motion — Spec

**Goal:** Gel looks and moves like a finished Mac app: a real app icon and brand mark, one motion system used everywhere, and purposeful animation on every moment of the demo path (launcher answer, citation → page, leak caught, stats tick up) — without changing any behaviour or slowing anything down.

## Behaviour

- **Assets:** an `AppIcon` asset catalog generated from code; a `GelDrop` brand mark used in the sidebar, launcher, onboarding and menu bar.
- **Motion system:** `Motion.snappy / .smooth / .pop` springs and a stagger helper in `Theme.swift`; every view uses them instead of ad-hoc curves. With Reduce Motion on, every one becomes a 150 ms opacity cross-fade and looping effects stop.
- **Shared components:** `GelButtonStyle` (primary/secondary), hover + press feedback on rows and chips, module header with subtitle, icon chips. Details in [design.md](design.md).
- **Per-surface polish:** shell (sliding sidebar selection, module transition, status footer), launcher, leak overlay, home, onboarding, library, history, redact sheet, settings — exactly as in [design.md](design.md).
- **Out of scope:** new features, copy changes beyond the header subtitles, sound, haptics, custom fonts, any change in `GelCore`.

## Acceptance criteria

- [ ] **AC1 Icon.** After `xcodegen generate` and a clean build, Finder, the Dock and ⌘Tab show the Gel icon (not the generic app icon).
- [ ] **AC2 Brand mark.** The sidebar, launcher glyph, onboarding hero and menu bar show the `GelDrop` mark; the menu bar mark is a template image (readable in light and dark menu bars).
- [ ] **AC3 Shell motion.** Switching modules slides the sidebar selection pill and transitions the content (seen in a screen recording frame sequence).
- [ ] **AC4 Launcher.** While waiting, the drop breathes and the skeleton shimmers; on done, citation chips arrive one after another and the panel grows without a jump. Time to first token is unchanged (same as before ± noise on the demo question).
- [ ] **AC5 Leak overlay.** Copying synthetic personal data and switching to Chrome slides the redesigned overlay in from the right; the countdown bar drains for 12 s and the overlay leaves to the right.
- [ ] **AC6 Home.** After a launcher answer, the "answers ran locally" / counts update with the rolling number transition, and the new row appears at the top of TODAY.
- [ ] **AC7 Onboarding.** Continue moves to the next step from the right, Back from the left; the page capsule moves with the step; the indexing step ends on the "files ready" check.
- [ ] **AC8 Light and dark.** Screenshots of Home, Library (with a citation), History, Redactions, Settings, the launcher and the leak overlay in both appearances: no hard-coded light surfaces, primary buttons keep the accent fill when the window isn't key.
- [ ] **AC9 Reduce Motion.** With Reduce Motion on, module switches and the leak overlay only cross-fade and the launcher drop doesn't breathe.
- [ ] **AC10 No regressions.** `Gel` and `gelcli` build, `GelCoreTests` pass, and `git diff --stat Gel/GelCore` is empty.
