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
- [x] **T5 R4 engine: preview API.** `Redactor.renderPages(url:findings:keep:) -> [RenderedPage]` (original image, redacted image, boxes with value + kept flag, page size) shared with `redactFile`, so After == the saved file. Owner: engine session. **Verify:** unit/CLI check — the saved PDF page image equals the preview's redacted image for the same inputs.
- [x] **T6 R4 UI: Before | After review.** Header copy, file tabs, side-by-side pages with outlines/kept tags, page arrows, findings list with live toggles and jump-to, live button counts. Owner: UI-polish session. **Verify:** redact 3 resumes → untick one name → Before shows it dashed "kept", After shows it visible, button reads "Black out N−1 items · Save 3 copies"; the saved file matches After.
  **Built (00:07, Oct 10):** `Gel/Gel/Redactions/RedactReview.swift` + `RedactSheet` wiring. Observed with `gel.debug.redact` on REYES | Mariano | Valdez: header "Gel will black out 36 of 36 items in 3 files", tabs with counts, Before/After at the same scale, grouped list with file + page, button "Black out 36 items · Save 3 copies". **Verified** by the engine session with synthesized real clicks on a fresh build: untick "0966 174 4548" → header 35 of 36, row struck through + "kept", Before kept outline, After number readable, button "Black out 35 items · Save 3 copies" → Save → 3 copies; OCR of Resume_REYES_REDACTED.pdf finds only that number, text layer 0 chars. The stray "team" box was an engine bug, now fixed. The "kept" tag moved to the box's right end (00:11 build) so it no longer covers the line above.
