# U10 · Multiple folders — Tasks

Status: `[x]` done and verified · `[~]` built, not verified · `[ ]` not started.

- [x] **T1 Folder list in GelCore.** `GelSettings.folderPaths` with upgrade from `folderPath` and `GEL_FOLDER` (`:`-separated); `FolderList.adding(_:to:)` normalization with notes. Files: `Gel/GelCore/Support/Settings.swift`, new `Gel/GelCore/Index/FolderList.swift`.
  **Verify:** unit tests for duplicate, child, parent; AC4 with a scratch `GEL_HOME`.
- [x] **T2 Indexer across folders.** `index(folders:progress:)`, `pruneOutside(_ folders:)`, trailing-`/` prefix in `pruneMissing`. Files: `Gel/GelCore/Index/Indexer.swift`.
  **Verify:** AC6 unit test; existing tests still pass.
- [x] **T3 AppState.** `folderPaths`, `addFolders(_:)`, `removeFolder(_:)`, per-folder missing set, rescan across folders. Files: `Gel/Gel/App/AppState.swift`.
  **Verify:** AC5.
- [~] **T4 Settings Folders card.** Rows, Add folders… (multi-select panel), remove, notes, env override, empty state. Files: `Gel/Gel/Settings/SettingsView.swift`.
  **Verify:** AC1, AC2, AC3, AC7 (screenshots in light and dark).
- [~] **T5 Onboarding and Home.** Multi-select chooser and capsule list; Home second line. Files: `Gel/Gel/Onboarding/OnboardingView.swift`, `Gel/Gel/Home/HomeView.swift`.
  **Verify:** onboarding run with a scratch `GEL_HOME`; Home shows "2 folders".
- [x] **T6 gelcli and docs.** `gelcli index <folder> [<folder>…]`; update `conventions.md` (`GEL_FOLDER`), indexing and settings specs, README feature table.
  **Verify:** AC8.

Done when: all [spec.md](spec.md) acceptance criteria are observed passing.

## Verification log (2026-10-09, 23:40–23:50)

- **Tests:** 21/21 `GelCoreTests` pass, including 7 in `FolderListTests` (duplicate, child, parent, siblings, several at once, sibling-prefix prune = AC6, upgrade + `GEL_FOLDER` = AC4/AC7 logic).
- **AC8:** `gelcli index "demo-data/HR Files" demo-data/Personal` (scratch `GEL_HOME`) → 65 files in 26.3 s; re-run → 0; a missing folder → "Folder not found".
- **AC4:** relaunched the app with only the old `folderPath` default → one `HR Files` row, 58 files, index unchanged (58 docs / 169 chunks).
- **AC1 (partly):** `gel.debug.addFolders` (D-052, calls the same `addFolders` as the panel) with HR Files + Personal → two rows (58 + 7), 65 docs in one pass, `gelcli search` finds Personal files. **Not observed:** the `NSOpenPanel` multi-select itself, and Library screenshots.
- **AC2:** removed Personal via the row's ✕ → dialog → Remove (pressed through Accessibility) → 58 docs, no Personal hits, 7 files still on disk. Cancel leaves the list unchanged; the dialog stays open on its own (checked 11 s).
- **AC3 (partly):** adding `HR Files/201 Files` → no row, note "Already included in HR Files." The parent case is unit-tested only (not run in the app, to avoid re-indexing the real index).
- **AC5:** scratch FolderA + FolderB; renamed A → row "Not found", Library banner names it, its document kept; a file copied into B searchable after 3 s; renamed back → note cleared.
- **AC7:** `GEL_FOLDER="HR Files:Personal"` (scratch `GEL_HOME`) → both rows, "Set by environment variable (GEL_FOLDER).", no Add or remove buttons.
- **Home:** "3 folders" observed. **Onboarding:** not run.
- **Unexplained, once:** during the first dialog test a missing folder's row was removed while the dialog was open, without our Remove press. Not reproduced in two later attempts (existing and missing folder).
