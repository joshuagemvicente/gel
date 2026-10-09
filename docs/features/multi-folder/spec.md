# U10 · Multiple folders — Spec

**Goal:** Gel reads a list of folders the user chooses in Settings, not just one.

## Behaviour

### The folder list

- **Storage:** `GelSettings.folderPaths: [String]` (UserDefaults key `folderPaths`), standardized absolute paths, in the order added.
- **Upgrade:** if `folderPaths` has never been set and the old `folderPath` key has a value, the list starts as `[folderPath]`. Nothing is re-indexed because of the upgrade.
- **Env override:** `GEL_FOLDER` still overrides the stored list and may hold several paths separated by `:` (`GEL_FOLDER="/a:/b"`). While it's set, the Settings list is read-only and shows "Set by environment variable (GEL_FOLDER)."
- **No duplicates or nesting.** When folders are added, the list is normalized:
  - A folder already in the list is ignored.
  - A folder **inside** a listed folder is not added; Settings shows "Already included in <parent name>."
  - A folder that **contains** listed folders replaces them (their documents stay indexed; they're now under the parent).
- Normalization lives in GelCore (`FolderList.adding(_:to:)` → new list plus notes) so it can be unit-tested.

### Adding and removing

- **Add folders…** opens `NSOpenPanel` with `canChooseDirectories = true`, `canChooseFiles = false`, `allowsMultipleSelection = true`. The user can ⌘-click several folders in one trip, or use the button again later.
- Added folders are indexed right away (incremental: only new or changed files).
- **Remove** (per row): a confirmation asks "Stop reading <name>?" with the message "Its files leave Gel's index. Nothing on your Mac is deleted." and buttons **Remove** (destructive) and **Cancel**. On Remove, the folder leaves the list and its documents leave the index. Files on disk are untouched.
- An empty list is allowed: search returns nothing and Settings shows "No folders yet."

### Indexing across folders

- `Indexer.index(folders:progress:)` gathers pending files across every **reachable** listed folder and indexes them in one pass, so progress reads "Indexing n of m" over the total.
- A **missing** folder is skipped and nothing under it is pruned (indexing E2 holds per folder). The other folders keep indexing.
- `pruneOutside(_ folders: [URL])` removes documents not under any listed folder. It runs after a remove and on launch.
- `pruneMissing(in:)` compares with a trailing `/` (fixes the sibling-prefix bug).
- The 5 s rescan covers every listed folder.
- Unreadable files (indexing E8) are collected across all folders into one list.

### Other screens

- **Onboarding (step 2):** **Choose folders…** uses the same multi-select panel; chosen folders appear as a list of capsules; **Use demo-data/HR Files** adds that folder. Continue is enabled with at least one folder.
- **Library:** the missing-folder banner names the missing folders: "Not found: <names>. Reconnect the drive or check Settings → Folders. Your index is kept."
- **Home index card:** under the counts, the folder's name when there's one, "<n> folders" when there are several, "No folder yet" when there are none.
- **gelcli:** `gelcli index <folder> [<folder>…]` indexes each given folder (it does not read or change the stored list).

## Out of scope

Per-folder pack choices, excluding subfolders, drag-and-drop onto the list, a per-folder filter in Library, and limits on the number of folders.

## Acceptance criteria

- [~] **AC1 Add several at once.** In Settings, **Add folders…**, ⌘-click `demo-data/HR Files` and `demo-data/Personal`, Open → two rows appear, indexing runs once over both, and Library lists files from both folders.
- [x] **AC2 Remove one.** Remove the `Personal` row → a confirmation appears; Cancel changes nothing; Remove → its files leave Library and search (`gelcli search` finds no `Personal` file); `HR Files` documents remain; nothing on disk changed.
- [~] **AC3 Nesting.** With `demo-data/HR Files` listed, adding a subfolder of it adds no row and shows "Already included in HR Files"; adding `demo-data` replaces both rows with one `demo-data` row and the file count doesn't drop.
- [x] **AC4 Upgrade.** With only the old `folderPath` default set (scratch `GEL_HOME`), launching shows that folder as the single row, and the first pass indexes 0 files.
- [x] **AC5 One missing folder.** With two folders listed, rename one while the app runs → its row shows "Not found", its documents stay in Library; a file copied into the other folder is searchable within 10 s. Renaming it back clears the note.
- [x] **AC6 Sibling prefix.** Unit test: with `/x/HR` and `/x/HR Files` listed, pruning a file deleted from `/x/HR` leaves every `/x/HR Files` document; `FolderList` tests cover duplicate, child and parent cases.
- [x] **AC7 Env override.** `GEL_FOLDER="<a>:<b>"` indexes both and Settings shows the list read-only.
- [x] **AC8 CLI.** `gelcli index "demo-data/HR Files" demo-data/Personal` indexes both and prints the combined totals.
