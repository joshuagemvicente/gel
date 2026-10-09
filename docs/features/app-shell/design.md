# U1 · App shell — Design

The shared look and feel for every Gel window. Other UI features reference this file instead of restating it.

## Main window layout

```
┌───────────────────────────────────────────────────────────────┐
│ ● ● ●                                                          │
├──────────────┬────────────────────────────────────────────────┤
│  ◉ Gel       │                                                │
│              │   <module content>                             │
│  ⌂ Home      │                                                │
│  ⟲ History   │                                                │
│  ▤ Library   │                                                │
│  ⛨ Redactions│                                                │
│    & Leak    │                                                │
│    Guard     │                                                │
│              │                                                │
│  ⚙ Settings  │   (Settings pinned at the bottom of the sidebar)│
└──────────────┴────────────────────────────────────────────────┘
```

- Sidebar width 200 pt; SF Symbols: `house`, `clock.arrow.circlepath`, `books.vertical`, `lock.shield`, `gearshape`.
- Content padding 28 pt; module title 26 pt semibold at the top-left of the content.

## Tokens

| Token | Light | Dark |
| --- | --- | --- |
| `canvas` | #F7F5F0 (warm off-white) | #1E1D1B (warm charcoal) |
| `card` | #FFFFFF | #282624 |
| `hairline` | #E7E3DA | #3A3733 |
| `textPrimary` | #1F1D1A | #F2EFE9 |
| `textSecondary` | #6F6A61 | #A8A296 |
| `accent` (deep green) | #1F7A4D | #3FB27A |
| `accentSoft` | accent at 12% | accent at 18% |
| `danger` | #B3402E | #E0705C |
| `dangerSoft` | danger at 12% | danger at 18% |
| `accentFill` (behind white text) | #1F7A4D | #217F51 |
| `hover` | text at 5% | text at 6% |

- Radii: cards 12 pt, chips/badges 999 (capsule), inputs 10 pt.
- Spacing scale: 4, 8, 12, 16, 24, 32.
- Type: SF Pro: 13 body, 11 caption, 15 emphasis, 26 title. Stat numbers: **New York** 34 pt regular (`.system(size: 34, design: .serif)`).

## Shared components (build once in the app target, e.g. `Gel/Gel/UI/Components/`)

| Component | Use |
| --- | --- |
| `Card` | Rounded container with `card` fill and hairline border |
| `ProviderBadge(provider, model)` | Capsule: **Local · model** (accentSoft + accent text) / **Cloud · model** (neutral) |
| `CitationChip(citation)` | Capsule button `1 · Resume_REYES p.2` |
| `StatCard(value, label)` | Serif number + caption label |
| `LockedLabel(org)` | Lock glyph + "Managed by <org>" in textSecondary |
| `EmptyState(symbol, title, hint)` | Centered, quiet; symbol in a 56 pt accent-soft circle |
| `IconChip(symbol)`, `SectionLabel`, `GelProgressBar`, `KeyHint` | Added by [polish](../polish/design.md) |
| `GelButtonStyle` (`.gelPrimary` / `.gelSecondary`) | Brand buttons; accent fill stays when the window isn't key |
| `GelMark` / `GelDrop` | Brand mark (Brand.swift); same path as the app icon (`GelDropPath.swift`) |

## Menu bar

- Icon: SF Symbol `drop` (template) normally; `cloud` while the cloud cooldown is active; `exclamationmark.triangle` when local is unavailable and no cloud is configured.
- Menu (in order): status line (disabled item), separator, Open launcher ⌥Space, Open Gel, separator, Pack ▸, Pause Leak Guard (checkmark when paused), separator, Quit Gel ⌘Q.

## Motion and accessibility

- Motion tokens `Motion.snappy` / `.smooth` / `.pop` (critically damped springs; `pop` for arrivals only) and the stagger helper live in `Theme.swift`; values and per-surface rules in [polish/design.md](../polish/design.md). Reduce Motion turns every one into a 150 ms cross-fade.
- No continuous animation in the main window, and no window-frame animation while SwiftUI animates ([D-047](../../project/decisions.md)).
- Every control has an accessibility label; badges read "Answered on this Mac" / "Answered by cloud fallback".
- Minimum hit target 28 pt; text contrast ≥ 4.5:1 against its background.
