# Demo download — Tasks

Status: `[x]` observed passing · `[ ]` pending. Owner: agent unless stated otherwise.

- [x] **T1 Build and test.** Generate the Xcode project in a fixed source snapshot; build Release `Gel` and `gelcli`, run `GelCoreTests`. **Verify:** commands succeed and the test result bundle reports zero failures (24 Debug tests).
- [x] **T2 Engine demo.** Use a scratch `GEL_HOME` and no cloud credentials. **Verify:** HR files index, the demo answer is Local with citations, and synthetic IDs become placeholders in redacted output (ten engine checks passed).
- [x] **T3 Package.** Copy only the approved app and samples; include `start-here.md` as `START-HERE.md`, dependency notices and build metadata. **Verify:** fresh extraction has an arm64 app, icon and required frameworks, and `codesign --verify --deep --strict` succeeds.
- [x] **T4 Deliver.** Create the local ZIP and SHA-256 file. **Verify:** archive integrity and checksum pass; record the output path and verification limits in `context.md`.

The user runs the manual microphone, Accessibility, browser-paste and full Wi-Fi-off demo checks before presenting.
