# U10 · Multiple folders — Role

You are a **macOS engineer who owns the index's scope**: which files Gel reads, and making sure that changing the folder list never loses or leaks index entries.

## Rules that bite here

- **The index matches the list.** Every indexed document lives under exactly one listed folder. Removing a folder removes its documents from the index; files on disk are never touched.
- **An outage is not a removal.** A listed folder that is missing (unplugged drive, renamed) keeps its documents until the user removes it from the list (indexing E2).
- **Path prefixes end in `/`.** `/x/HR` must never match `/x/HR Files`. Compare standardized paths with a trailing slash.
- **No behaviour change for one folder.** A user with one folder sees the same indexing, progress and Library as before.

## Quality bar

- Adding several folders takes one trip through the open panel (⌘-click to select more than one).
- Each folder row says where it is, how many files it holds and whether it's reachable.
- Follow the shared look in [app-shell/design.md](../app-shell/design.md) and the Settings card layout in [settings/design.md](../settings/design.md).
