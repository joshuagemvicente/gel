# S3 · Demo video — Spec

**Goal:** one ~60-second **motion-graphics** video (captions only, no voice, no music) that demos Gel's core features for the AppBuildersPH submission and X post. Animated typography, callouts and transitions frame **real captures of the running macOS app**; nothing is mocked up. The website is not shown: the product is the Swift app.

## Approach

- **Motion graphics shell:** rendered programmatically with Remotion (React + headless Chromium → H.264 via ffmpeg) from `video/` in the repo. Brand tokens come from `docs/features/app-shell/design.md` and `polish/design.md` (warm canvas, deep green accent, the Gel drop, SF Pro, New York for stat numbers).
- **Real captures inside the shell:** every feature beat shows a screenshot or short clip of the actual app on this Mac, placed in a window frame with animated callouts. Captures live in git-ignored `media/captures/` and are copied into `video/public/captures/` (git-ignored) at render time.
- **Honest content:** the only numbers shown are measured ones from `docs/project/decisions.md` (D-030, D-036, D-065). Any sped-up clip carries a visible speed tag. Voice is shown only if the capture shows it; the baseline is the typed question.

## Who does what

| Step | Claude | User |
| --- | --- | --- |
| Storyboard, captions, timing | writes [design.md](design.md) | confirms |
| Captures | writes the capture list; captures them if asked (launching the built app) | or captures them into `media/captures/` |
| Build | Remotion project, all scenes, render v1 | — |
| Review | fixes notes, renders v2 | watches, approves |

## Must-show beats (in this order, ~60 s total)

| # | Time | Beat | Shows |
| --- | --- | --- | --- |
| 1 | 0–5 s | Hook | The problem: HR files carry government IDs and salaries, and they get pasted into cloud AI |
| 2 | 5–10 s | Meet Gel | Drop mark, name, tagline; Wi-Fi switched off (everything that follows runs on the Mac) |
| 3 | 10–24 s | Ask | Launcher: the Taglish question, the answer with citation chips and the **Local · Qwen3 4B** badge |
| 4 | 24–32 s | Verify | Library viewer: the cited resume page with the passage highlighted |
| 5 | 32–42 s | Redact | Redact sheet Before \| After: burned-in boxes over IDs; originals untouched |
| 6 | 42–52 s | Leak Guard | Copy an employee record → chatgpt.com → overlay names what would leak → ⌥⌘V pastes placeholders |
| 7 | 52–56 s | Local stack | WhisperKit · Apple Vision · BGE-M3 · Qwen3 4B · SQLite, all on the Mac; cloud fallback off by default and redacted-only |
| 8 | 56–60 s | End card | Gel · "Private AI for your files. Runs on your Mac." · Team 12M · `github.com/joshuagemvicente/gel` · #AppBuildersPH |

A beat whose feature isn't working at capture time is dropped and the rest re-timed; it is never faked.

## Captures (`media/captures/`, PNG at native resolution, or `.mov` for clips)

| File | What | Beat |
| --- | --- | --- |
| `C1-launcher.png` (+ optional `C1-launcher.mov` of the answer streaming) | ⌥Space launcher after answering *"Sino sa applicants ang may 5+ years sa payroll?"*: chips + Local badge visible | 3 |
| `C2-viewer.png` | Library viewer on the cited resume page, passage highlighted, "Cited passage · page n of m" pill | 4 |
| `C3-redact.png` | Redact sheet in Before \| After review with boxes over IDs | 5 |
| `C4-overlay.png` (+ optional `C4-overlay.mov`) | Leak overlay over chatgpt.com in Chrome (logged out), "This would leak: …" | 6 |
| `C5-pasted.png` | chatgpt.com input after ⌥⌘V showing placeholders | 6 |
| `C0-home.png` (optional) | Main window Home with stat cards | 2 background |

Rules for every capture: synthetic `demo-data/` only, Do Not Disturb on, Dock and desktop icons hidden, no account names or avatars, light appearance.

## Output

- Source: `video/` (Remotion project, committed; `node_modules/`, `out/`, `public/captures/` git-ignored).
- Final: `media/out/gel-demo-v<N>.mp4`: 1920×1080, 30 fps, H.264 (High, yuv420p, `+faststart`), silent AAC track, 55–65 s, < 100 MB.

## Acceptance criteria

- [ ] Duration 55–65 s; beats 1–8 present unless a feature was dropped (logged in `docs/project/decisions.md`).
- [ ] Every app visual is a real capture from `media/captures/`; no recreated UI; the website never appears.
- [ ] No number on screen that isn't in `decisions.md`; every sped-up clip shows its speed tag.
- [ ] No personal or secret data visible (checked on a frame contact sheet of the export).
- [ ] Captions ≥ 42 px at 1080p, each on screen ≥ 1.5 s, readable with sound off.
- [ ] `ffprobe` confirms H.264/AAC, 1920×1080, 30 fps; the file plays in QuickTime and the browser.
- [ ] The user has approved the final version.
