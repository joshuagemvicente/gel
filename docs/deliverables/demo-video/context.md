# S3 · Demo video — Context

## Why it exists

A ~1-minute demo video is a required submission field, it is what the X post ([S2](../x-post/spec.md)) carries, and it doubles as the **backup** if the live demo fails on stage ([S6](../demo-day-runsheet/spec.md)).

## Where it sits

- **Upstream:** the working app (feature freeze ~06:00 Oct 10); demo beats in `docs/project/demo-and-submission.md`; `demo-data/` files.
- **Downstream:** [S2 x-post](../x-post/spec.md) (attachment), [S1 submission-form](../submission-form/spec.md) (video field), [S6 run sheet](../demo-day-runsheet/spec.md) (backup on the laptop).
- **Owner:** Claude writes the shot list and edits; the user records the takes and approves the cut.

## Current state

- **Oct 10 (user decision):** the video is a motion-graphics cut (Remotion, `video/`) that frames real captures of the app; spec and design rewritten and approved. Captions only; the website is never shown.
- The Remotion project renders all eight beats; a capture that is missing renders as a labelled slot. Captures are listed in [captures.md](captures.md) and go in `media/captures/`.
- Claude could not capture the app from this session (no screen-recording permission for the shell, no desktop-control tools), so the user captures; see captures.md.
- `ffmpeg` 9.0.2 (Homebrew) adds the silent AAC track and `+faststart` after the Remotion render (`video/scripts/render.sh`).

## Facts and gotchas

- Record with macOS's built-in **⌘⇧5 → Record Entire Screen** (`.mov`) at native resolution; one take per shot is easier to edit than one long take.
- The leak beat uses **chatgpt.com in Chrome**, not the ChatGPT app (it also uses ⌥Space; decision D-019). Use a Chrome profile with no personal avatar, or log out: chatgpt.com's sidebar shows the account name.
- Turn on **Do Not Disturb** and hide the Dock and desktop icons before recording.
- The Wi-Fi-off moment must be visible (menu bar Wi-Fi icon or Control Center) to prove "works offline".
- Check Homebrew's ffmpeg has `drawtext` (`ffmpeg -filters | grep drawtext`). If not, render captions as PNG overlays instead.
- Sound: no voiceover and no music by default (no licensing risk, works muted on X). A silent AAC track is still included because some players reject video-only files.
- X limits: up to 2:20, ≤ 512 MB, MP4 H.264 + AAC. The submission form may want a URL instead of a file (see [S1](../submission-form/context.md)).

## Related

[spec](spec.md) · [design](design.md) · [tasks](tasks.md) · [S2 x-post](../x-post/spec.md)
