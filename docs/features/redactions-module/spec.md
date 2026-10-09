# U8 · Redactions & Leak Guard module — Spec

**Goal:** one place for everything Gel kept from leaving: redacted files, the Leak Guard log, and the DPO report export. Also owns the redact flow started from the Library.

## Redact flow (started from Library → Redact)

1. A sheet lists the selected files and runs `PIIDetector.detectFull` on each file's extracted text (progress per file; layer 3 may take a few seconds per file).
2. Findings grouped by category with counts, each value with a checkbox (checked = redact). A note says when the LLM pass was unavailable or ran on the cloud.
3. **Redact n files** → `Redactor.redactFile(url, findings:, keep:)` per file → logs `redaction` + `redaction_item` events and a `redactions` row → the sheet shows the outputs with **Reveal in Finder**.

## Module view

- **Redacted files:** from `Store.redactions()`: date, source name, output name, counts summary; open / reveal.
- **Leak Guard log:** from `leak_caught` and `leak_item` events: time, app, summary of categories and counts. No content.
- **Export report:** date range (default last 30 days) → `DPOReport.export` → reveal the CSV and PDF in Finder (policy-dpo-report spec).

## Review screen: Before | After (R4, supersedes the list-only review)

The review step must make the outcome obvious before anything is written.

- **Header (plain outcome):** "Gel will black out **15 of 17** items in 3 files." Subline: "Untick anything you want to keep visible. Your original files are never changed; redacted copies are saved to a Redacted folder." AI line: "Checked on this Mac by patterns, name detection and the local AI." (or "…via the cloud fallback (redacted text)" / "AI check unavailable — review the list manually").
- **File switcher** (when several files): one tab per file with its count ("Resume_REYES · 6").
- **Side by side, same page, same scale:**
  - **Before** = the original page. Every finding is outlined: solid red tint = will be blacked out; dashed grey outline + small "kept" tag = unticked.
  - **After** = exactly what the saved copy will look like, rendered by the same code that writes it (black boxes flattened).
  - Page arrows when the file has more than one page; both sides stay on the same page.
- **Findings list underneath:** grouped by category with counts and a group checkbox; each row = value · label · page. Everything starts **ticked**. Toggling a row updates both pages immediately. Clicking a row jumps both pages to it and pulses its box.
- **Button:** "Black out 15 items · Save 3 copies" (counts live). Cancel writes nothing.
- **Sheet size:** at least 1040 × 720 so each page is readable.

## Acceptance criteria

- [ ] Redacting 3 demo resumes produces 3 `_REDACTED.pdf` files listed here.
- [ ] Unticking a value in the preview leaves it visible in the output.
- [ ] The Leak Guard log shows caught leaks with counts only.
- [ ] Export writes both files and reveals them.
