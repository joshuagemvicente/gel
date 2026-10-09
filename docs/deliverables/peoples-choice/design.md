# S7 · People's Choice — Design

## Closing screen (`closing-screen.html`)

```
┌──────────────────────────────────────────────────────────────┐
│                                                              │
│                           Gel                                │  ← wordmark, ~18% of screen height
│          Private AI for your files. Runs on your Mac.        │  ← tagline, ~4.5% height
│                                                              │
│      ✓ Works offline   ✓ Cites every answer   ✓ Stops leaks   │  ← three proof points, only if built
│                                                              │
│            People's Choice: vote for 12M                      │  ← the ask, accent color
│      github.com/joshuagemvicente/app-hackathon · #AppBuildersPH │  ← small footer
└──────────────────────────────────────────────────────────────┘
```

- Colors and type follow `docs/features/app-shell/design.md` (warm, minimal); system font stack only (`-apple-system`), so it renders offline.
- Sizes in `vh`/`vw` so it scales from 1280×720 to 1920×1080 without scrolling.
- Contrast ≥ 7:1 for the ask and tagline (projectors wash out color).
- No animation except an optional 300 ms fade-in on load.
- Proof-point list is generated from what passed S6; a cut feature's check is removed.

## The ask (copy direction)

Plain and specific: the product, the team, the action. For example: "If Gel would keep your files safe, vote 12M for People's Choice." Final wording in `peoples-choice.md`.

## Hallway demo state

Laptop on, Gel running on pack HR, chatgpt.com open in Chrome, `employee_record.txt` open beside it, Wi-Fi either way (Leak Guard runs locally). Reset after each visitor: clear the chatgpt.com input, re-copy the sample.
