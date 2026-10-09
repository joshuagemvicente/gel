# U6 · Home — Tasks

Status: `[x]` done and verified · `[~]` built, not verified · `[ ]` not started.

- [~] **T1 Stat cards + index card.** `HomeView` reading `DPOReport.totals()` and store counts. Files: `Gel/Gel/Home/HomeView.swift`.
  **Verify:** after `gelcli ask` on the same `GEL_HOME`, "answers ran locally" shows 100%.
- [~] **T2 TODAY activity.** Merge today's history, redactions and `leak_caught` events (with their `leak_item` summary) into one time-sorted list.
  **Verify:** ask, redact and trigger a leak → three rows in order.
- [~] **T3 Live refresh.** Post `GelActivityChanged` from query, redaction and Leak Guard paths; Home observes it and window activation.
  **Verify:** stats update without switching modules.

Done when: all [spec.md](spec.md) acceptance criteria are observed passing.
