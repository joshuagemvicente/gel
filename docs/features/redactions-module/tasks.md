# U8 · Redactions & Leak Guard module — Tasks

Status: `[x]` done and verified · `[~]` built, not verified · `[ ]` not started.

- [~] **T1 Redact sheet: scan.** For each URL: extract text → `detectFull` with progress and cancel; collect findings per file. Files: `Gel/Gel/Redactions/RedactSheet.swift`.
  **Verify:** 3 demo resumes → findings grouped by category with plausible counts; "AI check" caption correct.
- [~] **T2 Redact sheet: review and write.** Checkboxes (group + item) → `keep` set → `Redactor.redactFile` per file → `Store.saveRedaction` + `redaction`/`redaction_item` events → results with Reveal; post `GelActivityChanged`.
  **Verify:** 3 `_REDACTED.pdf` files exist; an unticked value is still visible in its output; Home stats move.
- [~] **T3 Module view.** Redacted files, Leak Guard log (from events), empty states. Files: `Gel/Gel/Redactions/RedactionsView.swift`.
  **Verify:** after T2 and a caught leak, both lists show entries with counts only.
- [~] **T4 Export report.** Date range → `DPOReport.export` → `NSWorkspace.activateFileViewerSelecting`.
  **Verify:** CSV + PDF written and revealed; a script confirms no ground-truth values or file names inside.

Done when: all [spec.md](spec.md) acceptance criteria are observed passing.
