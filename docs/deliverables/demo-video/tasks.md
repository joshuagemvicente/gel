# S3 · Demo video — Tasks

Legend: `[x]` done and verified · `[~]` done, not verified · `[ ]` not started. Owner in brackets.

- [ ] **T1 Tooling.** [Claude, after user OK] `brew install ffmpeg`; add `media/` to `.gitignore`; create `media/raw`, `media/frames`, `media/out`. **Verify:** `ffmpeg -version` runs; `ffmpeg -filters | grep drawtext` shows the filter (else switch to PNG captions); `git status` doesn't list `media/`.
- [ ] **T2 Shot list final.** [Claude] Update [design.md](design.md) → Shots to what's actually built at the 06:00 freeze (check each feature's `tasks.md`). **Verify:** user agrees with the list.
- [ ] **T3 Record.** [user, ~06:00–06:30] Follow Recording setup; record S01–S06 (+S07) into `media/raw/`. **Verify:** every file exists and opens in QuickTime.
- [ ] **T4 Review footage.** [Claude] Extract frames at 2 fps into contact sheets; check for private data and failed takes; pick the best takes and cut points. **Verify:** `cut-list.md` lists every segment with in/out times; problem takes reported to the user for re-recording.
- [ ] **T5 Edit v1.** [Claude] Trim, speed-up with tags, captions, end card, export per [spec](spec.md) → Output. **Verify:** `ffprobe` matches the spec; a contact sheet of the export shows every caption and no private data.
- [ ] **T6 Review → v2.** [user → Claude] User watches v1 and sends notes; Claude renders v2 (and v3 if needed by 07:30). **Verify:** user approves.
- [ ] **T7 Hand off.** [Claude] Final path given to the user for S2; a copy at `~/Desktop/gel-demo-backup.mp4` for the stage backup (S6). **Verify:** file plays from the Desktop with Wi-Fi off.

Done when: all [spec.md](spec.md) acceptance criteria hold.
