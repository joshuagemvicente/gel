# S9 · Website — Design (v2, "midnight instrument")

Status: **approved and built Oct 10 2026.** Replaces v1 "Warm paper, one green" (in Git history at `cb14cad`). Direction is the user's Linear style reference, with four user choices (see [context.md](context.md) → Decisions): acid-lime CTA with the green Gel drop as the logo, dark only, restyle plus layout, and a "Runs on" strip instead of customer logos.

Near-black canvas, white type at tight tracking, hairline borders instead of shadows, one acid-lime button per view. The product recreations (launcher, leak overlay) are the only colour and texture on the page.

## Two palettes, one rule

- **Site chrome** (nav, type, sections, buttons, cards, tables, footer) uses only the greys below and acid lime.
- **Product frames** (the launcher and leak-overlay recreations) use **Gel's own dark appearance** from `Theme.swift`: green citation dots, green "Paste redacted", the danger edge. They show the real app, so they look like it. These colours never appear outside a product frame.

## Tokens

Written as shadcn variables in `app/globals.css`, so the existing components keep working. The `dark` class is fixed on `<html>`; there is no light theme.

| Variable | Value | Style name | Used for |
| --- | --- | --- | --- |
| `--background` | `#08090a` | Void | Page canvas |
| `--card` | `#0f1011` | Carbon | Cards, showcase frame, nav when scrolled |
| `--popover`, `--muted`, `--secondary` | `#161718` | Obsidian | Elevated panels, table header, snippet header |
| `--border`, `--input` | `#23252a` | Graphite | Hairlines, card edges, ghost button outline |
| `--border-strong` | `#383b3f` | Smoke | Section separators |
| `--foreground` | `#ffffff` | Paper | Headings, emphasis |
| `--body` | `#d0d6e0` | Mist | Body copy, nav links, ghost button text |
| `--muted-foreground` | `#8a8f98` | Fog | Secondary text, captions, icons |
| `--faint` | `#62666d` | Ash | Decoration only (dividers, inactive dots). Fails 4.5:1, so never for text |
| `--primary` | `#e4f222` | Acid Lime | The Download button, and nothing else |
| `--primary-foreground` | `#08090a` | Void | Text on lime |
| `--accent` | `rgb(255 255 255 / 0.05)` | | Pill and badge fill, hover fill, selection |
| `--accent-foreground` | `#d0d6e0` | Mist | Text on that fill |
| `--ring` | `rgb(208 214 224 / 0.5)` | Mist 50% | Focus ring |
| `--destructive` | `#eb5757` | Coral | Error toasts only |
| `--app-accent`, `--app-accent-soft`, `--app-danger`, `--app-card`, `--app-hairline` | Theme.swift dark values | | Product frames only |
| `--drop-top` → `--drop-bottom` | `#6ADDA3 → #24885A` | | The Gel drop (Brand.swift dark) |

**Radii:** 4 px badges, 6 px buttons, inputs and snippets, 12 px cards and window frames, 9999 px pills. Nothing larger than 12 px.

**Depth:** a 1 px Graphite border, or `inset 0 0 0 1px #23252a`, separates surfaces. No drop shadows on cards. The only shadows: the lime button's inset stack (`0 5px 2px / 0 3px 2px / 0 1px 1px`, black at 1–8%) and `0 4px 32px rgb(8 9 10 / 0.6)` under product frames on the hero floor. The style guide's 0.5 px hairlines render as 1 px here: 0.5 px disappears on 1× screens.

## Type

**Font is Inter (D-081).** A brief switch to Manrope (D-080) was reverted the same day; Inter from `inter-ui` with `cv01`, `ss03` and `zero`, as described below, is the site font.

**Inter** (variable, rsms's `inter-ui` build through `next/font/local`; Google's copy lacks these features, D-074) for everything, with `font-feature-settings: "cv01", "ss03", "zero"`. **JetBrains Mono** only for commands, the hash, the build line, step numbers and keyboard shortcuts. (The style guide names Berkeley Mono, which is a paid font; JetBrains Mono is its listed substitute.) Weights are 400, 510 and 590 only; nothing at 600 or bolder. Tailwind's `font-medium` and `font-semibold` are remapped to 510 and 590 (D-075).

| Role | Size / line height | Weight | Tracking | Colour |
| --- | --- | --- | --- | --- |
| Hero | 64/64 (≥1024 px), 48/50 (≥640), 40/44 | 510 | −0.022em | Paper |
| H2 | 48/48 (≥1024), 32/36 | 510 | −0.022em | Paper |
| H3 | 20/27 | 590 | −0.012em | Paper |
| Body | 16/24 | 400 | 0 | Mist |
| Body small | 15/24 | 400 | −0.011em | Mist or Fog |
| Caption, nav | 13/16 | 400 | 0 | Fog / Mist |
| Label (eyebrow) | 13/16, sentence case | 510 | 0 | Fog |
| Mono | 13/22 | 400 | −0.013em | Mist |

The v1 uppercase green mono eyebrows go: eyebrows become plain 13 px Fog labels.

## Layout

- Max width 1200 px. Side padding 24 px, 16 px under 640 px.
- Sections 96 px apart on desktop, 64 px on mobile, each opened by a 1 px Smoke rule. No alternating bands: every section sits on Void.
- No three-column card grids. Sections are text-left/visual-right pairs or single columns.
- The nav is fixed: transparent on Void at the top, Carbon at 85% with a backdrop blur and a Graphite bottom border once scrolled.

```
┌──────────────────────────────────────────────────────────────────┐
│ ◆ Gel        How it works  Privacy  Install  FAQ   (Download)    │ nav 56 px, white pill
├──────────────────────────────────────────────────────────────────┤
│ Private AI for your Mac                                          │ label
│ Ask your files.                                                  │ hero 64, left
│ Keep them on your Mac.                                           │
│ Gel answers questions about…            [↓ Download for Mac]     │ subcopy left,
│                                          Install guide →         │ CTAs right (stack <1024)
│ Demo build · 14.4 MB · macOS 15+ · Apple silicon                 │ mono meta
│ ┌──────────────────────────────────────────────────────────────┐ │
│ │░░░░░░░░░░░░ showcase frame, gradient floor ░░░░░░░░░░░░░░░░░│ │ up to 1280 px,
│ │        ┌──────────── launcher (product frame) ──────────┐    │ │ bleeds past 1200
│ │        └────────────────────────────────────────────────┘    │ │
│ └──────────────────────────────────────────────────────────────┘ │
│ Runs on your Mac with  Ollama  Qwen3 4B  BGE-M3  Apple Vision …  │ strip, one row
├──────────────────────── Smoke rule ──────────────────────────────┤
│ What Gel does.            │ ▸ Answers with sources.              │ text-left /
│                           │ ─────────────────────────────────    │ stacked rows
│                           │ ▸ Personal data stays here.          │
│                           │ ─────────────────────────────────    │
│                           │ ▸ Leaks caught before you paste.     │
├──────────────────────────────────────────────────────────────────┤
│ How it works / From a folder to an answer you can check.         │
│ 01 Choose a folder   text          │  [folders card]             │ three pairs,
│ 02 Ask from anywhere text          │  [⌥ Space card]             │ text left,
│ 03 Open the passage  text          │  [passage card]             │ visual right
├──────────────────────────────────────────────────────────────────┤
│ Privacy / Your files never leave your Mac.  │ [leak overlay]     │ pair
│ intro · two notes                           │                    │
│ [What runs where table, full width]                              │
├──────────────────────────────────────────────────────────────────┤
│ Install            │ ① Download and check it                     │ sticky heading
│ Four steps to a    │ ② Drag Gel to Applications                  │ left (≥1024),
│ working install.   │ ③ Open it the first time                    │ numbered rail
│                    │ ④ Install Ollama and the models             │ right
├──────────────────────────────────────────────────────────────────┤
│ Requirements card                │ FAQ accordion                 │
├──────────────────────────────────────────────────────────────────┤
│ footer: drop · team line · disclosures │ mono build · sha · source│
└──────────────────────────────────────────────────────────────────┘
```

## Components

| Piece | Spec |
| --- | --- |
| **Download (primary)** | Lime fill, Void text, 6 px radius, 10 × 16 px padding, 14 px/510, −0.011em, the lime inset shadow stack. Hover: 90% lime. Press: scale 0.98. Used in the hero and install step 1, never twice in one screen. |
| **Nav Download** | White pill: Paper fill, Void text, 9999 px radius, 8 × 16 px padding, 13 px/510. |
| **Ghost button / link** | "Install guide →": Mist text, 14 px, no fill, arrow nudges 2 px on hover. Outline variant: Graphite 1 px border, 6 px radius, 8 × 12 px padding, 13 px. |
| **Nav links** | 13 px/400 Mist, 8 × 12 px padding, Paper on hover. |
| **Logo** | Green Gel drop (unchanged SVG) and "Gel" at 16 px/510 Paper. |
| **Showcase frame** | Carbon, 12 px radius, inset Graphite hairline, 24 px padding (16 px mobile). Behind it, the **hero floor**: a linear gradient from Void at 10% to Mist at 100%, laid over the frame at low opacity (tuned so the frame's edge stays visible; target ~6–10%). It's the only gradient on the page. |
| **Window frame** | Carbon, 12 px radius, Graphite border, three Ash traffic-light dots, 13 px Fog title. No shadow. |
| **Launcher recreation** | Same content and sequence as v1. Uses product-frame colours: green citation dots, `--app-card` fill. The "Local · qwen3 4B" badge becomes a 4 px-radius badge (`rgb(255 255 255 / 0.05)`, Fog text, mono 12 px). |
| **Leak overlay recreation** | Same content as v1, product-frame colours, 12 px radius. |
| **Runs-on strip** | Label "Runs on your Mac with" (13 px Fog), then the names as text, 15 px/510 Fog, 48 px gaps, wrapping to two rows on mobile: Ollama · Qwen3 4B · BGE-M3 · Apple Vision · NaturalLanguage · SQLite FTS5. Text, not logos (no third-party marks to license, nothing implying endorsement). WhisperKit is left out: voice isn't verified, so the site doesn't mention it. |
| **Claim rows** | 16 px Fog line icon, H3 title, Body text; rows separated by Graphite hairlines, 24 px vertical padding. |
| **Step visuals** | Cards: Carbon, Graphite border, 12 px radius. Folder icons and the "58 files ready" dot in Fog/Mist (not green: they're site chrome, not a product frame). The passage highlight uses `--accent` with a Mist outline. |
| **Table** | In a Carbon card. Header row Obsidian, 13 px/510 Fog. Rows 15 px, Graphite hairlines. The tick is Mist, not green. |
| **Install rail** | 24 px circles: Obsidian fill, Graphite border, mono 12 px Mist. 1 px Graphite rail. |
| **Snippet / terminal** | Carbon body, Obsidian header, 6 px radius, Graphite border. `$` prompt and comments in Fog, `✓` in Mist. Tabs are pills: `rgb(255 255 255 / 0.05)` when selected, 9999 px radius, 12 px. |
| **Accordion** | Carbon card, Graphite row hairlines, 15 px/510 Paper questions, Mist answers. |
| **Badges** | 4 px radius, `rgb(255 255 255 / 0.05)`, 12 px Fog, 0 × 6 px padding. |
| **Toasts** | Sonner on Obsidian with a Graphite border, Paper text. |
| **Focus** | 2 px Mist ring at 50%, 2 px offset, on every interactive element. |

## Motion

Unchanged from v1 except the dot field is removed. Entrances: 8 px rise and fade, 400 ms, once. Hover: 150 ms `cubic-bezier(0.4, 0, 0.2, 1)`. The drop breathes only while the launcher is "thinking". `prefers-reduced-motion`: opacity only, finished states shown.

## Copy

**AI-leak messaging backed by Cyberhaven research (user, Oct 10, D-079).** Supersedes the hero and claims wording below. Title "Gel: use AI without leaking personal data"; eyebrow "For everyone who pastes work into AI"; H1 "Use AI without leaking personal data."; hero visual = Leak Guard over a generic AI chat (`paste-catch-demo.tsx`, warning only, not the paste outcome). New **Research** section after the hero ("Most leaks into AI aren't malicious. They're copy and paste."): 39.7% of AI interactions involve sensitive data; on average every 3 days; personal accounts ChatGPT 32.3% / Claude 58.2% / Perplexity 60.9%; 82% of the top 100 AI apps medium to critical risk; quote "AI-related threats are almost always unintentional." Each figure is footnoted to the Cyberhaven page it was checked on. Claims lead with "Caught before you paste."; How it works becomes "Uploading the file itself? Send a redacted copy." with the redaction review recreation; the Leak Guard overlay leaves the Privacy section (it's in the hero).

**General positioning, HR as the example (user, Oct 10, D-078).** Supersedes the HR-only wording below: title "Gel: auto-redaction on your Mac"; eyebrow "Auto-redaction on your Mac"; H1 "Share files without the personal data."; subcopy lists "ID numbers, bank and card details, salaries, addresses and names"; a new "For anyone who sends documents." section (Work: HR and admin teams, tagged "The example on this page" · Personal: your own documents) after the claims; How it works and the hero caption name the HR résumés as the example; the FAQ lists both rule sets (Work: HR, Personal). Install keeps Work: HR for the sample files.

**Redaction-first positioning (user, Oct 10, D-077).** The page sells Gel as auto-redaction for HR teams; search is a supporting section.

- **Metadata:** title "Gel: auto-redaction for HR files on your Mac"; OG headline "Share HR files without the personal data."
- **Hero:** eyebrow "Auto-redaction for HR files"; H1 "Share HR files without the personal data."; subcopy "Gel finds government ID numbers, salaries, bank accounts and addresses in your PDFs, scans and photos, then saves a copy with them blacked out. You review every item before it's saved, and it all runs on your Mac."; visual: the redaction review recreation (`redact-review-demo.tsx`, Resume_REYES.pdf page 1 from `ground_truth.json`, the app's own strings).
- **What Gel does:** "Finds the personal data for you." · "Blacked out for good." · "Caught at the paste, too."
- **How it works:** "From a folder of HR files to copies you can share." Select the files ("Redact 3 files") → Review Before and After (untick to keep) → Save the redacted copies ("Saved 3 redacted files. Originals are unchanged.").
- **Privacy intro:** "…Gel finds and blacks them out on your Mac, so a file never has to be uploaded to be redacted." Table rows lead with detection and redaction.
- **Also in Gel (new, after Privacy):** "Ask your files, and see the page it came from." with the launcher demo.
- **Install step 4:** first try is Library → select three résumés → **Redact 3 files**; questions second.
- **FAQ:** adds "What does Gel find?", "Does it catch everything?" (synthetic test set: every ID, card, phone, email, address, bank account and salary value; names about 73% before the AI pass; D-036) and "Can someone remove the black boxes?" (no text layer; OCR finds none of the values; D-036).

The earlier copy below is kept for reference.


All v1 copy stays. Two additions: the claims section gets a visible H2, "What Gel does." (it was screen-reader only), and the strip label "Runs on your Mac with". Eyebrows keep their words but lose the uppercase.

## Assets

- `public/dmg-window.png` unchanged (the DMG is light; it sits in a Graphite-bordered 12 px frame).
- `app/opengraph-image.tsx`: Void background, Paper headline at weight 510, Fog subline, the app icon.
- `theme-color` meta: `#08090a`.
