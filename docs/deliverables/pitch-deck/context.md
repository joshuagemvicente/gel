# S8 · Pitch deck — Context

## Why it exists

The user asked (Oct 10, early morning) for a short deck to frame the 5-minute pitch, built in **Canva**. It supersedes the earlier "no slides" choice in [S4](../pitch-script/role.md); the live demo stays the centre of the pitch.

## Where it sits

- **Upstream:** [S4 pitch-script](../pitch-script/spec.md) (blocks and timing), the research report `reports/Sensitive data in AI tools.md` (the two stats and their attributions), `docs/project/product.md`, measured numbers in `docs/project/decisions.md` (D-030, D-036), brand colours in `docs/features/app-shell/design.md` and the Gel drop in `docs/features/polish/design.md`.
- **Downstream:** S4 gets slide cues (`[SLIDE n]`); [S6 run sheet](../demo-day-runsheet/spec.md) gets "deck open in Keynote/Preview, offline" in pre-flight; [S7](../peoples-choice/spec.md)'s closing screen becomes the last slide (the HTML file stays as a backup).
- **Owner:** Claude writes the outline and builds the Canva design; the user reviews, exports if needed, and presents.

## Current state

- Canva connector exists in the registry but is **not connected** in this session (the user must click Connect and sign in). Its tool list (search, create, autofill, import from URL, export) is only visible after connecting.
- No outline yet.

## Facts and gotchas

- **Offline presenting:** Wi-Fi is off for the demo, and Canva's Present mode runs in the browser. Present from an exported **PDF (Preview full screen) or PPTX (Keynote)** stored on the laptop, not from canva.com.
- Switching deck ↔ app on stage: deck full screen in its own Space; ⌘Tab to Gel/Chrome for the demo, ⌘Tab back. Keep slide 4 ("Live demo") showing before switching.
- Projector may be 1280×720: 16:9 slides, large type.
- The deck is private (git-ignored export files under `media/deck/`); the Canva design lives in the user's Canva account.
- Canva brand fonts may not match SF Pro; pick a close sans (e.g. Inter) and keep colours from the app.

## Related

[spec](spec.md) · [design](design.md) · [tasks](tasks.md) · [S4 pitch-script](../pitch-script/spec.md)
