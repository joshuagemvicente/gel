# U7 · History — Tasks

Status: `[x]` done and verified · `[~]` built, not verified · `[ ]` not started.

- [~] **T1 Grouped list + search.** `HistoryView` from `Store.shared.history()`. Files: `Gel/Gel/History/HistoryView.swift`.
  **Verify:** answers from `gelcli ask` (same `GEL_HOME`) appear under TODAY.
- [~] **T2 Detail.** Answer text, chips (→ library-viewer), badge, model; "What was sent" for cloud answers.
  **Verify:** a cloud answer (Ollama stopped, endpoint set) shows placeholders and no raw IDs in "What was sent".
- [~] **T3 Open in Gel.** Launcher link selects the answer in History.
  **Verify:** click Open in Gel after an answer → History opens on it.

Done when: all [spec.md](spec.md) acceptance criteria are observed passing.
