# Demo download — DMG design

The installer window is the first part of Gel people see after downloading it from the website. It should look like Gel: a warm off-white canvas, the green Gel drop, quiet type and a single clear action. Tokens come from `Gel/Gel/App/Theme.swift` and the [polish design](../../features/polish/design.md).

## Window

- **Content size:** 680 × 480 pt. Finder chrome is hidden: no toolbar, no sidebar, no status bar, no path bar. The window opens automatically when the DMG mounts.
- **View:** icon view with 96 pt icons and 13 pt labels at the bottom. Arrange by none, so the icons stay where they're placed.
- **Background:** one multi-resolution TIFF holding the 680×480 image and the 1360×960 Retina image (`tiffutil -cathidpicheck`), stored at `.background/background.tiff` on the volume.

## Layout (icon centres, pt, origin top-left)

```
┌──────────────────────────────────────────────────────────────┐
│                    Drag Gel to Applications                  │  title     y 58
│            Then open Gel from your Applications folder.      │  subtitle  y 84
│                                                              │
│        ╭─────╮                               ╭─────╮         │
│        │ Gel │   · · · · · · · · · · ·  ➜    │ App │         │  icons     y 186
│        ╰─────╯                               ╰─────╯         │
│          Gel                              Applications       │
│  ──────────────────────────────────────────────────────────  │  hairline  y 290
│  TRY THE DEMO  Copy Gel Sample Files to Documents first.     │  caption   y 312
│                                                              │
│     [Sample Files]        [START-HERE]      [About This Build]│  icons     y 384
└──────────────────────────────────────────────────────────────┘
```

| Item | Centre (x, y) |
| --- | --- |
| `Gel.app` | 180, 186 |
| `Applications` | 500, 186 |
| `Gel Sample Files` | 180, 384 |
| `START-HERE.md` | 340, 384 |
| `About This Build` | 500, 384 |

## Background art

- **Canvas:** brand `canvas` `#F7F5F0`, with a very soft radial lift (white at 60% opacity) behind the top row so the main action reads first.
- **Title:** "Drag Gel to Applications", SF Pro 22 pt semibold, tracking −0.4, `textPrimary` `#1F1D1A`, centred.
- **Subtitle:** "Then open Gel from your Applications folder.", SF Pro 13 pt, `textSecondary` `#6F6A61`, centred.
- **Arrow:** from x 262 to x 418 at y 186.
  - A gentle arc that rises 10 pt at the middle.
  - 2.5 pt round-capped dashes (6 on, 7 off) with a filled chevron head.
  - Colour: a gradient from `#4FC48A` to `#1F7A4D`, the same as the Gel drop, so the arrow reads as Gel flowing into Applications.
- **Lower section:**
  - A 1 px `hairline` line (`#E7E3DA`) from x 40 to x 640.
  - Under it, "TRY THE DEMO" in SF Pro 10.5 pt semibold, tracking +0.8, accent `#1F7A4D`.
  - After that, "Copy Gel Sample Files to Documents first." in SF Pro 12 pt, `textSecondary`.
  - The lower band below the line is tinted one step darker, `#EFECE6` (`viewerBackground`), so the setup items read as secondary.
- **Not included:** no logo lockup (the app icon is the logo, right there), no version number (it lives in `BUILD-INFO.json`), and no marketing copy.
- **Generation:** `scripts/make_dmg_background.swift` draws the art with Core Graphics at 1× and 2×. It's committed so the image can be regenerated, and its output goes in `dist/`.

## Appearance

The background stays light in both modes. A DMG can't switch its background with the system appearance, and the light canvas matches the app icon.

Finder may draw white icon labels in dark mode. This is checked by screenshot (spec acceptance criteria). If the labels are unreadable, the fallback is a darker tint behind each label row, `#E7E3DA` at the label positions. It's chosen only after the dark-mode screenshot, and logged in `docs/project/decisions.md`.

## Volume

- **Name:** "Gel".
- **Volume icon:** `.VolumeIcon.icns` built from the app icon set with `iconutil`, with the custom-icon flag set by `SetFile -a C`. It shows on the Desktop and in the Finder sidebar while the DMG is mounted.
- **Hidden items:** `.background`, `.VolumeIcon.icns`, `.fseventsd` and `.DS_Store`, all hidden with the usual dot-prefix rule.
- **`Gel.app` label:** shows "Gel.app" where Finder shows extensions; the extension is not hidden, because the flag would break the bundle's strict signature check (D-058).
- **`About This Build`:** a plain folder with a standard icon.
- **`Gel Sample Files`:** keeps the standard folder icon, so it reads as files to copy, not something to install.

## Build approach

1. Make a read-write HFS+ image in a scratch folder.
2. Copy in the staged items, mount the image, and set the window size, view options, background and icon positions with Finder AppleScript (`osascript`). This needs a one-time Automation permission for Finder.
3. Unmount and convert the image to UDZO.
4. If Finder scripting is blocked:
   - Ship the image without the custom layout, with icons in their default positions and no background.
   - Log that in `decisions.md`.
   - Tell the user. This isn't counted as a pass.

## Website hand-off

The same background art at 2× (`dist/dmg-window@2x.png`) and the light and dark screenshots of the mounted window are kept for the download page's "How to install" section. They are files only; Claude doesn't publish them.
