# S3 · Demo video — Design

Motion-graphics cut, 1920×1080, 30 fps, ~60 s. Captions only. Brand per [app-shell/design.md](../../features/app-shell/design.md).

## Look

- **Canvas:** warm off-white `#F7F5F0` for product beats; warm charcoal `#1E1D1B` for the hook and the end card. Text `#1F1D1A` / `#F2EFE9`; secondary `#6F6A61`; accent `#1F7A4D` (`#3FB27A` on dark); danger `#B3402E`.
- **Type:** SF Pro Display (system). Captions 56 px semibold, tracking −0.5, max 2 lines, ≤ 8 words per line, bottom-left on a 16 px padded `card`-coloured box when over a capture. Stat numbers in New York (serif) 96 px.
- **Brand mark:** the Gel drop path from `GelDropPath.swift` (same path as the app icon), vertical gradient `#4FC48A → #1F7A4D`, specular highlight. Drops in with a critically damped spring.
- **Capture frame:** captures sit in a rounded (14 px) window frame with a soft shadow, scaled to ~78% width, slight 1.00→1.04 drift (Ken Burns) over the beat. Callouts: 2 px accent rounded rect over the element + a short accent leader line + 28 px label; they pop in (scale 0.9→1, 35 ms stagger).
- **Motion:** springs only (response 0.28 snappy / 0.42 smooth / 0.35 pop at damping 0.72 for arrivals), matching the app's motion tokens. Hard cuts between beats, 8-frame cross-fade into the end card. No element animates longer than 450 ms except progress-style bars.

## Narration script (v2)

About 125 words at ~150 wpm. *Italic* = the user's own voice inside the recording.

| Time | Voice-over | On screen |
| --- | --- | --- |
| 0–6 s | "HR teams handle government IDs, salaries and addresses every day. And those files keep getting pasted into cloud AI." | Hook graphic; small label "HR & payroll teams · Data Privacy Act" |
| 6–11 s | "This is Gel: private AI for your Mac. First, Wi-Fi off." | Mark + name, then R1 |
| 11–24 s | "Press Option-Space and ask in Taglish." *"Sino sa applicants ang may 5+ years sa payroll?"* "Gel answers with its sources, right on this Mac." | R2; callouts: transcript, chips, Local badge |
| 24–31 s | "Click a source and the exact passage opens, highlighted." | R3 |
| 31–40 s | "Sharing files? Gel burns in redactions, even on scans. Originals stay untouched." | R4 |
| 40–52 s | "Copy an employee record into ChatGPT. Gel catches it, and Option-Command-V pastes placeholders instead." | R5 |
| 52–57 s | "Speech, OCR, search and answers run locally. The cloud only sees redacted text, and only if you allow it." | Stack pills, "25.5 s to index 58 files on an M2", cloud rule |
| 57–60 s | "Gel. Private AI for your files." | End card |

Subtitles: the same words, one phrase at a time (≤ 7 words), bottom-centre, 46 px semibold on a 85% card-coloured pill, clear of the footage.

## Scenes (v1, superseded by the table above)

| # | Frames (30 fps) | Scene | Motion | Caption |
| --- | --- | --- | --- | --- |
| 1 | 0–150 | Hook | Dark canvas. A document card ("201 File · Reyes") with masked lines `SSS 34-•••` `TIN •••` `₱ salary` rises; the ID lines detach and float up toward a cloud glyph; the cloud tints danger | "HR files are full of government IDs." → "And they get pasted into cloud AI." |
| 2 | 150–300 | Meet Gel | Cut to warm canvas. Drop pops in, "Gel" slides in beside it, tagline fades up. Top-right: Wi-Fi glyph gets a slash and a "Wi-Fi off" chip pops | "Gel. Private AI for your files." → "Wi-Fi off. Everything below runs on this Mac." |
| 3 | 300–720 | Ask | `C1` in the frame (clip if present, else still). The question types out in a replica of nothing: the caption carries it. Callouts in order: question field → citation chips → **Local · Qwen3 4B** badge | "Ask in Taglish." → "Get an answer with its sources." → "Answered on this Mac." |
| 4 | 720–960 | Verify | `C2` in the frame, zoom 1.0→1.15 toward the highlighted passage; callout "Cited passage · page 2" | "Every answer opens its source, highlighted." |
| 5 | 960–1260 | Redact | `C3` in the frame; a wipe reveals the After side left→right; callouts on two boxes | "Redact scans and PDFs." → "Originals stay untouched." |
| 6 | 1260–1560 | Leak Guard | `C4` (clip if present): callout on the overlay summary line; then cut to `C5` with callout on the placeholders | "Copy a record into ChatGPT…" → "Gel catches it. Pastes placeholders instead." |
| 7 | 1560–1680 | Local stack | Five pills stagger in: WhisperKit (speech) · Apple Vision (OCR) · BGE-M3 (search) · Qwen3 4B (answers) · SQLite (index). Under them, one measured line: "58 demo files indexed in 25.5 s on an M2" (D-030). Small line: "Cloud fallback: off by default. Redacted text only." | "Speech, OCR, search and answers. All on this Mac." |
| 8 | 1680–1800 | End card | Dark canvas, drop + "Gel", tagline, then `Team 12M · github.com/joshuagemvicente/gel · #AppBuildersPH` | — |

If `C1-launcher.mov` exists, scene 3 plays it at up to 2× with a `2×` pill top-right while sped up; the answer's final frame holds for the callouts.

## Speed tag

`2×` (or the real factor) in a 28 px capsule, top-right, visible for the whole sped-up span.
