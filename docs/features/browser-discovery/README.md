# F5a · Automatic browser discovery

**Status:** specification only; implementation has not started. The user confirmed the scope through the OpenCode questionnaire on 2026-10-10. Review this written brief before authorizing app changes.

**Goal:** protect sensitive clipboard text in browsers and web-link apps that macOS discovers, including browsers missing from Gel's static list, without reading websites or installing extensions.

## Read in this order

| File | Purpose |
| --- | --- |
| [role.md](role.md) | Engineering responsibilities, privacy rules and completion gates |
| [context.md](context.md) | Current implementation, integration points and verified platform facts |
| [spec.md](spec.md) | Behaviour, precedence, state transitions, limits and acceptance criteria |
| [interfaces.md](interfaces.md) | Proposed GelCore contracts, native adapters and concurrency boundaries |
| [design.md](design.md) | Settings layout, row states, interactions and user-facing copy |
| [tasks.md](tasks.md) | Ordered implementation tasks, dependencies and verification requirements |
| [verification.md](verification.md) | Automated test matrix and synthetic-data app walkthroughs |

The behaviour contract lives in `spec.md`. Interfaces and tests implement that contract; they do not introduce separate product rules.

## Confirmed decisions

| Questionnaire | Decision |
| --- | --- |
| Q1 · Website scope | Protect any website in an eligible browser; do not inspect tabs or webpages. |
| Q2 · Enrollment | Add discovered browsers/web-link handlers to coverage without a setup step. |
| Q3 · Repeat warnings | Warn once per clipboard change per protected app, identified by bundle ID. |
| Q4 · Company control | An explicit `watchedApps` policy replaces automatic and user-selected coverage. |
| Q5 · User controls | Unmanaged app coverage supports manual additions and exclusions. |
| Q6 · Existing clipboard | Check current text when monitoring starts or resumes. |
| Q7 · Counts | Count one incident and its detected items per clipboard change in a running Gel session. |
| Q8 · Classification | Include web-link handlers such as link routers; provide exclusions instead of claiming perfect browser classification. |
| Q9 · Attribution | Attribute the counted incident to the first protected app that triggers it. |
| Q10 · Restart | Keep warning/accounting state in memory; restarting Gel can count the unchanged clipboard again. |
| Scope confirmation | Include clipboard-freshness checks and preserving findings through block-mode replacement. Deliver a spec only, without app changes or a commit. |

## Ownership and related briefs

- [Leak Guard](../leak-guard/spec.md) owns the existing detector, overlay and safe-paste fundamentals. This extension replaces its static-only membership source and global once-per-change warning rule when implemented.
- [Policy and DPO report](../policy-dpo-report/spec.md) owns policy actions and the existing counts-only report format. This extension preserves explicit-list replacement semantics.
- [Settings](../settings/spec.md) gains the coverage section described here.
- [Packs](../packs/spec.md) owns detection patterns. Browser discovery does not broaden the TIN pattern or add detection types.
- [App shell](../app-shell/spec.md) continues to own service startup and menu-bar pause controls.

**Current limitations remain visible:** Gel reacts to clipboard changes/app activation. It does not intercept every paste, prove that text reached a website, or guarantee that every app with an embedded web view qualifies for discovery.
