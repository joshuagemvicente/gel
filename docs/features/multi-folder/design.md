# U10 · Multiple folders — Design

## Settings → Folders card

Replaces the Folder card (same position, first in the column). Title becomes **Folders**.

```
┌ Folders ────────────────────────────────────────────────────┐
│ Gel reads these folders and their subfolders.                │
│ Files never leave your Mac.                                  │
│                                                              │
│ 📁 HR Files                                   58 files   ✕   │
│    ~/projects/app-hackathon/demo-data/HR Files               │
│ 📁 Contracts                                  12 files   ✕   │
│    ~/Documents/Contracts                                     │
│ 📁 Scans                                  ⚠ Not found    ✕   │
│    /Volumes/USB/Scans                                        │
│                                                              │
│ (Add folders…)  (Reindex now)        70 files · 912 passages │
│ Already included in HR Files.                                │
└─────────────────────────────────────────────────────────────┘
```

- **Row:** folder symbol, folder name (13 pt medium), file count on the right (11 pt, textSecondary, monospaced digits), remove button (`xmark`, 18 pt hit target, `accessibilityLabel` "Remove <name>") that opens a SwiftUI `.confirmationDialog`. Below, the full path (11 pt monospaced, textSecondary, middle-truncated, `~` for the home folder). Rows separated by a hairline.
- **Missing row:** count replaced by `exclamationmark.triangle.fill` + "Not found" in `Theme.danger`; tooltip "Your index is kept until the folder is back or you remove it."
- **Buttons:** **Add folders…** and **Reindex now** (disabled with no folders), standard buttons like the rest of Settings. Totals on the right.
- **Note line** (11 pt, textSecondary) under the buttons for normalization notes from the last add; it clears on the next add or remove.
- **Unreadable files:** the existing "Couldn't read <file>: <reason>" lines stay under the card body.
- **Env override:** caption "Set by environment variable (GEL_FOLDER)." Buttons and remove are hidden.
- **Empty:** a single line "No folders yet. Add the folders Gel should read." in place of the rows.

## Onboarding step 2

- Title: "Choose the folders Gel should read". Subtitle unchanged.
- Button: **Choose folders…**. Each chosen folder appears as a capsule (as today), stacked, max width 440 pt; a capsule has a small `xmark` to remove it.
- **Use demo-data/HR Files** link stays and adds that folder.

## Home index card

Second line: folder name (one folder) · "<n> folders" (several) · "No folder yet" (none). While indexing it still reads "Reading n of m…".

## Copy

| Where | Text |
| --- | --- |
| Settings card description | Gel reads these folders and their subfolders. Files never leave your Mac. |
| Child folder note | Already included in <parent name>. |
| Parent folder note | <parent name> now includes <n> folder(s) you'd added. |
| Missing row | Not found |
| Remove confirmation | Title: Stop reading <name>? · Message: Its files leave Gel's index. Nothing on your Mac is deleted. · Buttons: Remove (destructive), Cancel |
| Empty list | No folders yet. Add the folders Gel should read. |
| Env override | Set by environment variable (GEL_FOLDER). |
