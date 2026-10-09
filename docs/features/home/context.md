# U6 · Home — Context

## Why it exists

Wispr Flow's home shows words, wpm and a streak; Gel's shows **privacy stats**: items kept on device, leaks caught, share of answers run locally. In demo step 4 the stats visibly tick up after the leak is caught. It converts the **Local AI (25%)** story into numbers.

## Where it sits

- **Upstream:** `DPOReport.totals(since:)` (events), `Store.history()`, `Store.redactions()`, `Store.events(since:)`, `Store.documents()`, `Store.chunkCount`, `AppState` (index progress).
- **Downstream:** none.

## Current state

- Nothing built in the app target. `DPOReport.Totals` exposes `leaksCaught`, `itemsProtected`, `redactions`, `localAnswers`, `cloudAnswers`, `byCategory`, `localShare`.

## Facts and gotchas

- Event kinds that feed the stats: `leak_caught` (one per caught paste), `leak_item` and `redaction_item` (counts per category), `redaction`, `query` (provider local/cloud). Leak Guard and the redact flow must log these for Home to move.
- `localShare` returns 1 when there are no answers; show "—" instead of 100% until the first answer.
- Refresh triggers: window becomes key, and notifications posted after query, redaction and leak events (e.g. `Notification.Name("GelActivityChanged")`).

## Related docs

[spec](spec.md) · [design](design.md) · [tasks](tasks.md) · [policy-dpo-report](../policy-dpo-report/spec.md)
