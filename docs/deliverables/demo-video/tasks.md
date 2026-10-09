# S3 · Demo video — Tasks

Legend: `[x]` done and verified · `[~]` done, not verified · `[ ]` not started. Owner in brackets.

- [x] **T1 Tooling.** _(Oct 9 22:15: ffmpeg 9.0.2 installed; `media/` git-ignored.)_
- [x] **T2 Spec → motion graphics.** _(Oct 10: approved via questionnaire.)_ [Claude] Rewrite spec/design for the motion-graphics cut. **Verify:** user confirms.
- [ ] **T3 Captures.** [user; see captures.md] Produce `media/captures/C1–C5` per the spec table. **Verify:** each file exists, opens, shows only synthetic data.
- [x] **T4 Remotion project.** _(Oct 10 04:38: `media/out/gel-demo-v1.mp4` rendered with capture slots; ffprobe: h264 1920×1080 30 fps yuv420p + aac, 60.0 s, 6.8 MB.)_ [Claude] `video/` with scenes 1–8, brand tokens, capture frame + callout components, silent audio. **Verify:** `npx remotion render` produces `media/out/gel-demo-v1.mp4`; `ffprobe` matches the spec.
- [~] **T5 Frame check.** _(Contact sheet of v1 reviewed: all captions present, no private data; re-check after the real captures.)_ [Claude] Contact sheet of the export at 2 fps; every caption visible ≥ 1.5 s; no private data; no website. **Verify:** sheet reviewed.
- [ ] **T6 Review → v2.** [user → Claude] Notes → v2. **Verify:** user approves.
- [ ] **T7 Hand off.** [Claude] Final path for S2; copy at `~/Desktop/gel-demo-backup.mp4`. **Verify:** plays with Wi-Fi off.

- [x] **T8 v1 review.** _(Oct 10: [review-v1.md](review-v1.md); v2 spec approved with changes: compact Samantha voice, Claude records.)_
- [x] **T9 Narration + v2 shell.** _(Oct 10: `npm run vo` → 9 lines, 41.9 s; v2 draft `media/out/gel-demo-v2.mp4` 61.1 s, −16.1 LUFS, synced subtitles, push transitions; recording slots remain.)_
- [x] **T10 Record.** _(Oct 10 06:05–06:20: Claude drove the Debug app via hooks and recorded R2–R5 (D-085); R1 Wi-Fi and the spoken question dropped. An earlier 19-min session recording held none of the takes and was deleted.)_
- [x] **T11 Cut + callouts.** _(Oct 10: `media/out/gel-demo-v3.mp4`, 63.9 s, H.264/AAC 1920×1080 30 fps, −16.1 LUFS; callouts measured on frames; 10× tag on scanning; contact sheet checked: only demo data, chatgpt.com signed out.)_
- [ ] **T12 User review of v3.** [user] **Verify:** user approves or sends notes.

Done when: all [spec.md](spec.md) acceptance criteria hold.
