# S3 · Demo video — Spec

**Goal:** one ~60-second captioned screen video of Gel actually working, edited by Claude from the user's raw takes, ready for X and the submission.

## Who does what

| Step | Claude | User |
| --- | --- | --- |
| Shot list and captions | writes [design.md](design.md) → Shots | reviews |
| Recording | — | records each shot as its own `.mov` into `media/raw/`, named `S01.mov`, `S02.mov`, … |
| Edit | frame extraction, cut list, trims, speed-ups, captions, title and end cards, export | — |
| Review | renders `v1`, fixes notes, renders `v2` | watches, approves or sends notes |

## Must-show beats (in this order)

1. **Hook (0–5 s):** the problem in one caption over the app: HR files full of government IDs, and people paste them into AI.
2. **Offline proof (5–10 s):** Wi-Fi visibly turned off.
3. **Ask (10–25 s):** ⌥Space, the Taglish voice question, the streamed answer with citation chips and the **Local** badge.
4. **Verify (25–33 s):** click the Reyes chip → her resume opens at page 2 with the passage highlighted.
5. **Leak catch (33–50 s):** Wi-Fi on, copy the employee record, switch to chatgpt.com → the overlay names what would leak → ⌥⌘V pastes placeholders.
6. **Close (50–60 s):** end card: Gel · "Private AI for your files. Runs on your Mac." · team 12M · repo URL · #AppBuildersPH.

If a beat's feature was cut by the freeze, the beat is dropped (not faked) and the remaining beats are re-timed. Redaction (Library → Redact) is the first substitute if a beat drops.

## Output

- Working files (git-ignored): `media/raw/`, `media/frames/`, `media/out/`.
- In the repo: `docs/deliverables/demo-video/cut-list.md` (shot, source file, in/out, speed, caption).
- Final: `media/out/gel-demo-v<N>.mp4`: 1920×1080, 30 fps, H.264 (High, yuv420p, `+faststart`), AAC 128 kbps (silent), 55–75 s, < 100 MB.

## Acceptance criteria

- [ ] Duration 55–75 s; beats 1, 2, 3 and 5 present unless their feature was cut.
- [ ] Every frame comes from the user's raw recordings of the running app; no mock-ups.
- [ ] Every sped-up segment shows its speed tag; no timing claim in a caption that isn't measured.
- [ ] No personal or secret data visible (checked on the frame contact sheet of the export).
- [ ] Captions are legible at phone size (≥ 42 px at 1080p) and on screen ≥ 1.5 s each.
- [ ] `ffprobe` confirms H.264/AAC, 1920×1080, 30 fps; the file uploads to X and plays.
- [ ] The user has approved the final version.
