# S9 · Website — Design

"Warm paper, one green." Gel's own tokens, laid out the way the calm, warm-paper systems in Refero Styles are: Cursor's button pair, window frame and code block; Perplexity's single accent and citation-first tone; Intercom's tone bands and mono eyebrows; Vercel's CLI panel with green ticks ([research §1.1](research.md#11-refero-styles-stylesreferodesign)). No glows, beams, particles or dark hero. The green drop is the only art.

## Tokens

shadcn variables in `app/globals.css`, converted from `Theme.swift` (research §5, contrast checked to WCAG AA).

| Variable | Light | Dark | Gel token |
| --- | --- | --- | --- |
| `--background` | `oklch(0.970 0.007 88.6)` | `oklch(0.231 0.004 84.6)` | canvas |
| `--foreground` | `oklch(0.232 0.006 78.2)` | `oklch(0.953 0.009 84.6)` | textPrimary |
| `--card`, `--popover` | `oklch(1 0 0)` | `oklch(0.270 0.005 67.6)` | card |
| `--primary` | `oklch(0.515 0.110 156.8)` | `oklch(0.531 0.113 157.1)` | accent / accentFill |
| `--primary-foreground` | `oklch(1 0 0)` | `oklch(1 0 0)` | white |
| `--secondary`, `--muted` | `oklch(0.944 0.009 84.6)` | `oklch(0.270 0.005 67.6)` | viewerBackground (band) |
| `--muted-foreground` | `oklch(0.526 0.015 82.4)` | `oklch(0.714 0.018 84.6)` | textSecondary |
| `--accent` | `oklch(0.515 0.110 156.8 / 0.12)` | `oklch(0.684 0.133 158.4 / 0.12)` | accentSoft (dark 0.12, not the app's 0.18, for 4.5:1 text; D-061) |
| `--accent-foreground` | `oklch(0.515 0.110 156.8)` | `oklch(0.684 0.133 158.4)` | accent text and links |
| `--destructive` | `oklch(0.530 0.153 31.4)` | `oklch(0.672 0.144 31.6)` | danger |
| `--border`, `--input` | `oklch(0.916 0.013 86.8)` | `oklch(0.338 0.008 75.3)` | hairline |
| `--ring` | `oklch(0.515 0.110 156.8 / 0.5)` | `oklch(0.684 0.133 158.4 / 0.5)` | accent 50% |
| `--band` | `oklch(0.944 0.009 84.6)` | `oklch(0.205 0.004 84.6)` | viewerBackground; dark is a step below the canvas (D-061) |
| `--drop-top` → `--drop-bottom` | `#5BD195 → #1A6B43` | `#6ADDA3 → #24885A` | drop gradient, from `Brand.swift` (D-061) |
| `--shadow-float` | `0 0 1px #3A2F1E66, 0 1px 1px #3A2F1E0A, 0 12px 32px -8px #3A2F1E1A` | same in black at 35% | shadow (ElevenLabs whisper stack, warm) |

**Radius:** `--radius: 0.625rem` → buttons 8 px (`md`), code blocks and inputs 10 px (`lg`), cards 14 px (`xl`), window frames 18 px (`2xl`). No pill buttons.

**Depth:** hairline borders first. `--shadow-float` only on the floating window recreations.

## Type

Geist Sans for everything except commands, hashes and eyebrows, which use Geist Mono.

| Role | Size / line height | Weight | Tracking |
| --- | --- | --- | --- |
| Hero | 56/60, 40/44 under 640 px | 600 | −0.03em |
| H2 | 36/42, 28/34 under 640 px | 600 | −0.02em |
| H3 | 20/28 | 600 | −0.01em |
| Body | 17/26 | 400 | −0.01em |
| Small, meta | 14/20 | 400 | 0 |
| Eyebrow | 11 px mono, uppercase | 500 | +0.08em, accent |

## Layout

- Content max width 1120 px, 24 px side padding (16 px under 640 px).
- Section gap 96 px on desktop, 64 px on mobile.
- Sections alternate canvas and the `--muted` band instead of using divider lines (Intercom).
- Every section starts with a mono eyebrow, then the H2, then content.

```
┌───────────────────────────────────────────────────────────────┐
│ ◆ Gel     How it works  Privacy  Install  FAQ     ◐ [Download]│ nav, 64 px
├───────────────────────────────────────────────────────────────┤
│ PRIVATE AI FOR YOUR MAC                                       │
│ Ask your files.            ┌──────────────────────────────┐   │
│ Keep them on your Mac.     │ ◆ Sino sa applicants ang may…│   │ launcher
│                            │ Cruz, Santos and Reyes have… │   │ recreation
│ Cited answers from your    │ [1 Resume_CRUZ] [2 …] [3 …]  │   │ (window frame,
│ own documents. Nothing     │                    ⌂ Local   │   │ float shadow,
│ leaves without redaction.  └──────────────────────────────┘   │ dot pattern
│ [↓ Download for Mac] [Install guide]                          │ behind)
│ Demo build · 14.4 MB · macOS 15+ · Apple silicon              │
├───────────────────────────────────────────────────────────────┤
│ claim · claim · claim                                          │ 3 columns → stack
├────────────────────── band ───────────────────────────────────┤
│ HOW IT WORKS  1 Choose folders  2 Ask  3 Open the passage      │
├───────────────────────────────────────────────────────────────┤
│ PRIVACY   "What leaves your Mac" table  +  leak overlay        │
├────────────────────── band ───────────────────────────────────┤
│ INSTALL   ① verify  ② drag  ③ Open Anyway  ④ Ollama terminal  │ numbered rail
├───────────────────────────────────────────────────────────────┤
│ REQUIREMENTS card          FAQ accordion                       │
├───────────────────────────────────────────────────────────────┤
│ footer: build · sha · AppBuildersPH 2026 · source · disclosures│
└───────────────────────────────────────────────────────────────┘
```

## Components

| Piece | Built from | Notes |
| --- | --- | --- |
| Gel drop | Hand-built SVG of the `GelDrop` path, filled with `--gel-drop`, with a 45% white highlight | Breathes in the hero only (scale 0.98 → 1.06, 0.9 s, ease-in-out, alternate). |
| Buttons | shadcn `button` | Primary: green fill, white 14 px/500, 8 px radius, 40 px tall in the hero. Secondary: card fill and hairline border. Press scales to 0.97. |
| Window frame | Hand-built after Cursor's mockup | Card fill, hairline border, 18 px radius, three grey traffic lights, 13 px centred title, float shadow. |
| Launcher recreation | Hand-built inside the window frame | Demo question, three-line answer, citation chips (`1` in a 16 px green circle plus the file name) and a `cpu` **Local** badge, all as in the polish design. A one-time sequence: the question appears, a Text Shimmer "Thinking…", the answer fades in, then the chips arrive 35 ms apart. |
| Leak overlay recreation | Hand-built | 380 px card with a 3 px danger leading edge: "Gel caught a leak · Chrome", "This would leak: 2 names, 1 TIN, 1 phone", **Paste redacted ⌥⌘V** and Ignore. Uses only the demo sample's categories. |
| Commands, checksum | `@kibo-ui/snippet` | Mono 13 px, `$` prompt in muted text, copy button with a Sonner "Copied" toast. |
| Ollama walkthrough | `@cult-ui/terminal-animation` | Two tabs, "Install Ollama" and "Pull models", typed once when scrolled into view, with green `✓` lines (Vercel CLI panel). Never loops. |
| Install steps | Hand-built numbered rail | 28 px numbered circles on a 1 px hairline rail, one card per step. |
| What leaves your Mac | shadcn table styles in a card | Columns: Task · On your Mac · Internet. A green tick marks local work and muted text marks "Only as a fallback, redacted". |
| FAQ | shadcn `accordion` | |
| Section entrances | `@magicui/blur-fade` | 8 px rise and fade, about 400 ms, once, on view; children stagger 35 ms up to 8. |
| Hero texture | `@magicui/dot-pattern` | Hairline colour at 40% opacity, masked to fade out at the edges. |

## Motion

- Hover and colour changes: 150 ms `cubic-bezier(0.4, 0, 0.2, 1)`, in CSS.
- Entrances: once, on view. Nothing auto-loops except the hero drop.
- `prefers-reduced-motion: reduce`: opacity-only 150 ms fades, the terminal renders complete, the launcher shows its finished state, and the drop is still.

## Copy

Plain, short, and specific. No hype words. Headline and subcopy are a starting draft for the user to edit:

- **Hero:** "Ask your files. Keep them on your Mac." / "Gel answers questions about your own documents with citations, redacts personal data, and catches it before you paste it into a cloud AI."
- **Claims:** "Answers with sources." / "Personal data stays here." / "Leaks caught before you paste."
- **Privacy H2:** "Your files never leave your Mac." Then the table.
- **Not notarized note:** "This is an ad-hoc-signed demo build, not a notarized release. macOS will ask you to confirm the first time you open it."

## Assets

- `public/dmg-window.png`: the mounted-window screenshot (`dist/dmg-window-dark.png`), used in both themes because the DMG itself stays light (D-061).
- `app/icon.png` from the app icon at 512 px (`Gel/Gel/Assets.xcassets/AppIcon.appiconset`).
- `app/opengraph-image.tsx`: 1200 × 630, the canvas, the app icon and the hero headline, prerendered at build (D-062).
