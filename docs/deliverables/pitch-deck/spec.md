# S8 · Pitch deck — Spec

**Goal:** a short 16:9 Canva deck that frames the live demo in the 5-minute pitch, plus a Q&A appendix, exported for offline presenting.

## Slides (main deck, mapped to S4 blocks)

| # | S4 block | Headline (draft) | Content |
| --- | --- | --- | --- |
| 1 | 1 Hook (0:00) | Gel | Gel drop + wordmark, "Private AI for your files. Runs on your Mac.", Team 12M |
| 2 | 1 Hook (end) | Nearly 40% of AI interactions involve sensitive data | One big number; source line: Cyberhaven Labs, 2026 AI Adoption & Risk Report (222 companies, 2025 data) |
| 3 | 2 Problem | 83% of Filipino AI users bring their own AI | One big number; source: Microsoft & LinkedIn, 2024 Work Trend Index (PH). Sub-line: HR files hold SSS, TIN, salaries: Data Privacy Act data |
| 4 | 3–5 Demo | Live demo · Wi-Fi off | Divider shown while switching to the app |
| 5 | 6 Why local | Why it has to be local | Four tiles: Private · Works offline · Free per copy · Fast (58 files indexed in 25.5 s on an M2, measured) |
| 6 | 6 Why local (end) | The cloud only sees placeholders | Simple flow: file → on-device AI (Whisper, BGE-M3, Qwen3 4B) → answer; dotted optional path → redactor → cloud with `[SSS_1]` |
| 7 | 7 Business | HR teams first. Everyone next. | Teams: per seat, admin policy, counts-only DPO report · Personal: free · Next packs: finance, legal |
| 8 | 8 Close | Vote 12M for People's Choice | Mirrors `closing-screen.html`: Gel, tagline, three proof points (only if built), the ask, repo URL, #AppBuildersPH |

## Appendix (Q&A only, after slide 8)

A1 Measured on the M2 (D-030, D-036 numbers only) · A2 What runs locally vs needs internet · A3 Privacy rules (counts not content, redact before cloud, keys in Keychain) · A4 Sources (full citations for both stats).

## Outputs

- `docs/deliverables/pitch-deck/deck-outline.md` (public): slide text, sources, speaker cue per slide.
- The Canva design in the user's account (link recorded in `deck-outline.md`).
- `media/deck/gel-pitch.pdf` and `media/deck/gel-pitch.pptx` (git-ignored) for offline presenting.

## Acceptance criteria

- [ ] 8 main slides + up to 4 appendix slides, 16:9.
- [ ] Every number on a slide has its source on that slide (stats) or comes from `decisions.md` (measured); the two stats are on separate slides and never merged.
- [ ] No feature shown that isn't verified at the 06:00 freeze (proof points, demo claims).
- [ ] Headlines ≤ 8 words; body ≤ 20 words per slide; readable at 1280×720.
- [ ] Opens and presents with Wi-Fi off from the exported PDF or PPTX.
- [ ] S4 has `[SLIDE n]` cues at the right lines and still runs 4:15–4:40.
