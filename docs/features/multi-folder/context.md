# U10 · Multiple folders — Context

## Why it exists

People keep work files in more than one place: an HR share, a Downloads folder of scans, a Documents folder of contracts. Today Gel reads one folder, so the user has to move files or pick a common parent (often their whole home folder, which is slow to index and pulls in unrelated files). The user asked for Settings to hold a list of folders instead of one.

## Where it sits

- **Upstream:** `GelSettings` (stored folder list, `GEL_FOLDER` override), `Indexer` (enumerate, prune, index), `NSOpenPanel`.
- **Downstream:** `AppState` (rescan timer, progress, missing state, unreadable list), Settings Folder card, Onboarding folder step, Home index card, `gelcli index`. Search, answers, citations and redaction work on whatever is in the index, so they need no change.

## Current state

Built (see [tasks](tasks.md)): `GelSettings.folderPaths`, `FolderList`, `Indexer.index(folders:)`, Settings Folders card with remove confirmation, onboarding multi-select, Home "n folders", `gelcli index` with several folders. Not yet observed: the open panel's multi-select, onboarding.

## Before this feature

- `GelSettings.folderPath: String?` (UserDefaults key `folderPath`; `GEL_FOLDER` overrides it).
- `AppState.folderPath`, `setFolder(_:)` (prunes everything outside the new folder, then indexes), `indexNow(onlyIfPending:)` (one folder), `folderMissing: Bool`.
- `Indexer.index(folder:)`, `pending(in:)`, `pruneOutside(_:)`, `pruneMissing(in:)`.
- Settings Folder card: one path, **Choose…**, **Reindex now**, counts, missing note, unreadable list (`Gel/Gel/Settings/SettingsView.swift`).
- Onboarding step 2: **Choose folder…** and **Use demo-data/HR Files** (`Gel/Gel/Onboarding/OnboardingView.swift`).
- Home index card shows the folder's name under the counts (`Gel/Gel/Home/HomeView.swift`).

## Facts and gotchas

- **Prefix bug today:** `pruneMissing` uses `doc.path.hasPrefix(folder.path)` with no trailing `/`. With one folder it can't misfire; with siblings like `HR` and `HR Files` it would delete the wrong folder's documents. Fixed here.
- **Nested folders** would make one file belong to two list entries and be counted twice. The list is kept free of nesting (see spec).
- The rescan timer runs every 5 s while the app is open; with several folders it must stay cheap (it compares modification dates only).
- `GEL_FOLDER` is used for terminal and judge testing; it keeps working and can now hold several paths separated by `:`.

## Related docs

[spec](spec.md) · [design](design.md) · [tasks](tasks.md) · [indexing](../indexing/spec.md) · [settings](../settings/spec.md) · [onboarding](../onboarding/spec.md)
