# Demo download — Spec

Approved by the user on October 10, 2026: macOS demo ZIP, local file only.

## Contents

`dist/Gel-Demo-macOS-arm64.zip` extracts to a `Gel Demo/` folder containing:

- `Gel.app`: a Release build for Apple Silicon, minimum macOS 15, with its required embedded frameworks and app icon.
- `demo-data/HR Files`, `demo-data/Personal`, `demo-data/clipboard-samples`, the synthetic dataset README and ground truth. Exclude test-generated redactions, QA-only fixtures and hidden files.
- `START-HERE.md`: requirements, model installation, Gatekeeper/permission guidance and the typed-query → citation → redaction → Leak Guard demo path.
- `BUILD-INFO.json`: configuration, architecture, source revision/tree, build tools and the checks observed passing. Include no credentials, user preferences, local database or real documents.
- `THIRD-PARTY-NOTICES.txt`: license and notice text from the resolved Swift package dependencies.

Write a SHA-256 checksum beside the ZIP. Keep the ZIP and checksum out of Git. Leave GitHub visibility unchanged and do not upload the package.

## Acceptance criteria

- [x] Release `Gel` and `gelcli` builds succeed from the fixed snapshot; `GelCoreTests` pass (24 tests, Debug).
- [x] The snapshot's CLI indexes the synthetic HR folder, answers the demo question locally with citations, and detects/redacts synthetic IDs.
- [x] The extracted app has an arm64 executable, minimum macOS 15, app icon and embedded frameworks; strict code-signature verification succeeds.
- [x] The ZIP has the specified contents, excludes generated/private data, passes archive integrity checks and matches its SHA-256 checksum.
- [x] The setup guide states that models download separately and the demo is ad-hoc signed, not notarized. Record manual checks that have not run.

## Addendum: drag-to-install DMG (requested Oct 10)

The user will host a download website (Vercel or Cloudflare) and wants the familiar Mac install: open the DMG, drag Gel to Applications. The ZIP stays as is.

### Contents

`dist/Gel-macOS-arm64.dmg`, a compressed read-only image (UDZO), mounts as a volume named **Gel** showing:

- `Gel.app`: the **same** signed build as the ZIP (copied from it, not rebuilt), so the verified binaries and signature carry over.
- `Applications`: a link to `/Applications`, placed to the right of `Gel.app`.
- `Gel Sample Files/`: the same synthetic `demo-data` as the ZIP. A mounted DMG is read-only and disappears on eject, and Gel writes redactions next to the source, so the guide tells people to drag this folder to Documents first.
- `START-HERE.md`, and an `About This Build` folder holding `BUILD-INFO.json` and `THIRD-PARTY-NOTICES.txt`, so the window shows five items instead of six.
- The window layout, background art and volume icon in [design.md](design.md).

`START-HERE.md` in the DMG covers the DMG steps (drag the app, drag the sample files to Documents, eject). The ZIP's copy stays unchanged. Write `dist/Gel-macOS-arm64.dmg.sha256` next to the DMG. Both stay out of Git.

Signing doesn't change: the app is ad-hoc signed and the DMG is unsigned and not notarized. Anyone downloading it from a website still sees macOS's "could not verify" prompt and must use System Settings → Privacy & Security → **Open Anyway**. On macOS 15, Control-click → Open no longer skips this prompt.

### Acceptance criteria

- [x] `hdiutil verify` passes; the image mounts read-only as **Gel** with exactly `Gel.app`, `Applications`, `Gel Sample Files`, `START-HERE.md` and `About This Build`. No other items are visible while hidden files are hidden.
- [x] `Gel.app` in the image passes `codesign --verify --deep --strict` and has the same code-directory hash as the ZIP's app.
- [x] `Gel Sample Files` copied out of the image indexes with `gelcli` (scratch `GEL_HOME`) to 58 HR files; no QA fixtures, `Redacted/` outputs or hidden files.
- [~] Screenshots of the mounted window in light and dark appearance match [design.md](design.md): window size, icon positions, sharp art on Retina, and every label readable. **Dark observed** (`dist/dmg-window-dark.png`); light not captured (the Mac stays in dark mode). Window is 480 pt tall (D-057).
- [x] The DMG matches its SHA-256 file; its size is recorded in `context.md`.
- [ ] Not verifiable here, so left to the user: dragging to `/Applications` and opening a copy **downloaded from the website**, which has macOS's quarantine flag set, on a Mac that has never run Gel.
