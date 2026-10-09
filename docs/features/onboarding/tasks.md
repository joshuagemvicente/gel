# U5 · Onboarding — Tasks

Status: `[x]` done and verified · `[~]` built, not verified · `[ ]` not started.

- [x] **T1 Sheet and steps.** `OnboardingView` with the three steps from [design.md](design.md); shown by app-shell when `onboardingDone` is false. Files: `Gel/Gel/Onboarding/OnboardingView.swift`.
  **Verify:** with defaults reset and a fresh `GEL_HOME`, the sheet appears on launch.
- [x] **T2 Pack choice.** Selected cards → `GelSettings.activePacks`.
  **Verify:** choose Personal only → `activePacks == ["personal"]`.
- [x] **T3 Folder + indexing.** `NSOpenPanel` → `folderPath` → `Indexer().index(folder:progress:)` with progress; Continue in background hands progress to `AppState`.
  **Verify:** choosing `demo-data/HR Files` indexes 58 files; relaunch doesn't show onboarding again.

Done when: all [spec.md](spec.md) acceptance criteria are observed passing.
