# Demo download — Context

The user requested a downloadable product demo and approved an Apple Silicon/macOS 15+ ZIP containing `Gel.app`, synthetic samples and setup instructions. Models download separately. The repository is `https://github.com/joshuagemvicente/gel` and remains private; the local checkout keeps its existing folder name.

Other sessions may be editing this checkout. Build a fixed snapshot in a separate source and Derived Data directory, then commit that snapshot in coherent groups without discarding newer edits.

## Current state

Built and packaged from the final fixed snapshot, including the redaction-review fixes. The app, CLI, assets and synthetic dataset match source revision `981b872d5e41a7752a07d95f9205ec0c34e12cc3`.

- **Download:** `dist/Gel-Demo-macOS-arm64.zip` (13,037,514 bytes).
- **Checksum:** `dist/Gel-Demo-macOS-arm64.zip.sha256`; SHA-256 `b064a0692e9f736004da7e533b53f473825dd82adcdb40094d360ab0ed8846c4`.
- **Build:** Release arm64 `Gel` and `gelcli`, Xcode 26.3, minimum macOS 15.
- **Tests:** 24 Debug `GelCoreTests` passed, zero failures or skips. The initial attempt to run tests in Release failed because Release disables `@testable` imports; rerunning tests in Debug required no source change.
- **Engine:** all ten checks passed with cloud fallback disabled: 58 HR files indexed, clipboard detection, two-page resume preview, typed text redaction, repeat-output naming, stamped-scan redaction and government-ID recheck, the single-line honorific regression, the local demo answer with three citations, and local-only history stats.
- **Archive:** integrity and SHA-256 checks passed; a fresh extraction retained the executable permissions, app icon, arm64 architecture and valid embedded code signatures. It includes 11 dependency license/notice texts.
- **Warnings:** existing warnings remain for the unused `localError` in `ModelRouter.swift` and asynchronous `NSLock` use in `VoiceRecorder.swift`. This build uses the project's Swift 5 language mode; a Swift 6 migration is outside this task.

`dist/` is git-ignored. No release was published and repository visibility remains private. The archive's `BUILD-INFO.json` records the source revision and verification limits.

## Limits

No bundled Ollama, chat/embedding/speech model weights, notarization, hosted download or product video. Manual microphone, Accessibility, browser-paste and offline checks remain the user's responsibility unless observed passing in this packaging session.
