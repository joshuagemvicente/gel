# Demo download — Tasks

Status: `[x]` observed passing · `[ ]` pending. Owner: agent unless stated otherwise.

- [x] **T1 Build and test.** Generate the Xcode project in a fixed source snapshot; build Release `Gel` and `gelcli`, run `GelCoreTests`. **Verify:** commands succeed and the test result bundle reports zero failures (24 Debug tests).
- [x] **T2 Engine demo.** Use a scratch `GEL_HOME` and no cloud credentials. **Verify:** HR files index, the demo answer is Local with citations, and synthetic IDs become placeholders in redacted output (ten engine checks passed).
- [x] **T3 Package.** Copy only the approved app and samples; include `start-here.md` as `START-HERE.md`, dependency notices and build metadata. **Verify:** fresh extraction has an arm64 app, icon and required frameworks, and `codesign --verify --deep --strict` succeeds.
- [x] **T4 Deliver.** Create the local ZIP and SHA-256 file. **Verify:** archive integrity and checksum pass; record the output path and verification limits in `context.md`.

The user runs the manual microphone, Accessibility, browser-paste and full Wi-Fi-off demo checks before presenting.

## DMG (addendum)

- [x] **T5 Stage.** Extract the verified ZIP into a scratch folder; arrange `Gel.app`, the `Applications` link, `Gel Sample Files`, the DMG version of `START-HERE.md` and the two build files; make the background image. **Verify:** `codesign --verify --deep --strict` on the staged app; its code-directory hash matches the ZIP's app.
- [x] **T6 Build the DMG.** Make a read-write image, set the window layout, background and volume icon through Finder, then convert it to compressed read-only (UDZO). **Verify:** `hdiutil verify`; mount it and take a screenshot of the window.
- [x] **T7 Check and record.** Index the copied-out sample files with `gelcli`; write the SHA-256 file; record the size, checksum and limits in `context.md`. **Verify:** the DMG acceptance criteria in `spec.md`.

The user checks a download from their website on a clean Mac (quarantine, Open Anyway, first launch).

### DMG verification log (2026-10-10, 01:16–01:22)

- **T5:** staged `Gel.app` copied from the verified ZIP; strict `codesign` passes; CDHash `be7db4b2c8db31b2274f26b7a71f3513f43f28f9`, identical to the ZIP's app.
- **T6:** `hdiutil verify` VALID. Opening the DMG mounts the read-only volume **Gel** and opens the designed window by itself (680 × 480, D-057). The title bar shows the Gel volume icon. Visible items: Gel.app, Applications, Gel Sample Files, START-HERE.md, About This Build.
- **T7:** `Gel Sample Files/HR Files` copied out of the mounted image → `gelcli index` (scratch `GEL_HOME`) 58 files in 24.7 s, 58 documents / 169 chunks; `search "payroll specialist"` → Cruz, Santos. No hidden files or `Redacted/` in the sample folder.
- **Found and fixed:** hiding the `.app` extension broke strict signature verification; Finder dropped the volume icon; a 460 pt window clipped labels (D-057, D-058).
- **Not observed:** light-appearance screenshot; a website download with the quarantine flag set, on a Mac that has never run Gel (user).
