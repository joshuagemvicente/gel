# U11 · Model setup — Design

## Settings › Models card

Follows the existing `section(title, subtitle)` card and app-shell tokens. Subtitle: "Gel runs AI on this Mac with Ollama. Downloads come from ollama.com; none of your files are sent."

```
┌ Models ──────────────────────────────────────────────────────────────┐
│ ● Ollama is running · v0.34.4                                         │  ← state row (StatusDot + text + action)
│   [ Install Ollama… ]  /  [ Start Ollama ]  shown instead when needed  │
│                                                                       │
│ CHAT MODEL                                                            │  ← SectionLabel
│ ┌───────────────────────────────────────────────────────────────────┐ │
│ │ RECOMMENDED                                          ✓ In use      │ │  ← action column, 220 pt, right-aligned
│ │ Qwen3 4B Instruct                                                  │ │
│ │ 2.5 GB download · 8 GB RAM · ≈ 12.4 s to first words, 16.9 s full  │ │
│ └───────────────────────────────────────────────────────────────────┘ │
│ Speed: the demo question on an M2 with 16 GB, model loaded. …          │
│ ───────────────────────────────────────────────────────────────────── │
│ Embeddings  bge-m3 · 1.2 GB  ✓ downloaded                 [ Warm up ]  │
└───────────────────────────────────────────────────────────────────────┘
```

- **Cards:** full-width rows in a `VStack` (one preset after D-065; more stack below it). The In-use card gets the `accentSoft` fill and an accent hairline; the others use `canvas` with a `hairline` border and a 10 pt radius.
- **Buttons:** primary action `.gelPrimary`, small. Cancel and Retry are `.gelSecondary`. In use is a static label with `checkmark.circle.fill` in accent, not a button.
- **Downloading:** the button row becomes `GelProgressBar(animated: false)` with "42% · 1.1 of 2.5 GB" and a Cancel button. The row's height stays fixed, so nothing reflows per tick.
- **Warnings:** the RAM and disk warnings are amber (`.orange`) 11 pt text under the specs, prefixed with `exclamationmark.triangle.fill`. Errors use `Theme.danger`.

## Install sheet

A modal sheet, 440 pt wide.

- `IconChip("arrow.down.app")` and the title "Install Ollama".
- Rows: Source "ollama.com (official app)", Size "about 206 MB", Location the destination path.
- The privacy line in secondary text.
- Footer: Cancel, then **Install** (`.gelPrimary`).
- **While running:** the title becomes "Downloading Ollama…", followed by a progress bar, "Checking signature…" and "Opening Ollama…", in that order. Cancel stays available until the move.
- **Failure:** danger text with the reason, plus **Open download page** and **Close**.

## Sidebar footer

Same layout as indexing (D-047): one text line plus a static 2 pt bar at opacity 1 while downloading. No inserted views.
