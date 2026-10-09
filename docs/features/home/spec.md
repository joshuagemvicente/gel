# U6 · Home — Spec

**Goal:** make the value of local AI visible in numbers the moment the app opens.

## Behaviour

- Title: "Welcome back" (no user name needed).
- **Three stat cards** (serif numbers, label underneath), from `DPOReport.totals()`:
  1. `itemsProtected` — "items kept on device" (personal-data items caught by Leak Guard or redaction),
  2. `leaksCaught` — "leaks caught",
  3. `localShare` as a percentage — "answers ran locally" (shows "—" before the first answer).
- **Index card:** files and chunks indexed, last indexed time, folder name; a small "Indexing…" state.
- **TODAY list:** recent activity rows (time + one line): questions (with Local/Cloud badge), redactions ("Redacted 3 files"), leaks caught ("Leak caught in Chrome: 2 government ID numbers") — from `history`, `redactions` and `events`. Never document text beyond the user's own question.
- Refreshes when the window becomes active and after each query, redaction or caught leak.

## Acceptance criteria

- [ ] Stats change after a query, a redaction and a caught leak, without restarting.
- [ ] Before any activity, the cards show 0 / 0 / — and the TODAY list shows a friendly empty state.
