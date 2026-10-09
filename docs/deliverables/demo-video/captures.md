# S3 · Capturing the app frames

Five stills (plus two optional clips) of the real app go into git-ignored `media/captures/`. The motion-graphics shell in `video/` places them in window frames with callouts. Nothing else on screen is ever recreated.

## Before you start

- Gel running from `Gel/build/Build/Products/Debug/Gel.app`, light appearance, Ollama running with `qwen3:4b-instruct-2507-q4_K_M` loaded (ask the demo question once to warm it).
- Settings → Models → local URL must be `http://localhost:11434` (it was set to the dead test port 11999 on Oct 10; already switched back).
- Do Not Disturb on; Dock hidden (⌥⌘D); desktop icons hidden; no notifications.
- Library shows `~/Downloads` too (it is in `folderPaths`). Either remove it in Settings → Folders for the session, or type `Reyes` into the Library search before C2 so only demo files are listed.
- Chrome: a profile with no avatar or name, logged out of chatgpt.com, bookmarks bar hidden (⌘⇧B).

## The captures

Use ⌘⇧4 then Space to capture one window (adds the window shadow; fine), or ⌘⇧5 → Record Selected Portion for the clips. Save with exactly these names:

| File | State to capture |
| --- | --- |
| `C1-launcher.png` | ⌥Space → type *Sino sa applicants ang may 5+ years sa payroll?* → Enter → wait for the chips and the **Local · Qwen3 4B** badge. Capture the launcher panel. |
| `C1-launcher.mov` (optional) | Same, recorded from Enter until the badge appears. The video plays it at 2× with a `2×` tag. |
| `C2-viewer.png` | Click the Reyes chip → main window Library viewer with the highlighted passage and the "Cited passage · page n of m" pill. Capture the main window. |
| `C3-redact.png` | Library → select the three resumes → Redact → wait for the Before \| After review. Capture the sheet with boxes visible on the After side. |
| `C4-overlay.png` | Open `demo-data/clipboard-samples/employee_record.txt`, ⌘A ⌘C, switch to chatgpt.com in Chrome → the Leak Guard overlay shows "This would leak: …". Capture the whole screen (the overlay sits top-right). |
| `C4-overlay.mov` (optional) | Same, from the ⌘C until the overlay is fully in. |
| `C5-pasted.png` | Press ⌥⌘V with the chatgpt.com input focused → placeholders appear. Capture the Chrome window. |
| `C0-home.png` (optional) | Main window Home with the stat cards. |

Check each file: synthetic data only, no account names, no real file names from Downloads.

## Render with the captures

```bash
cd video && npm run render
```

This copies the captures in, renders, adds the silent audio track and writes `media/out/gel-demo-v1.mp4` (pass a number to `scripts/render.sh` for v2, v3…). Open `npm run studio` to scrub the timeline; callout boxes are fractions in each scene file under `video/src/scenes/` and may need nudging to the real layout.
