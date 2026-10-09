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

## Acceptance criteria

- [ ] Redacting 3 demo resumes produces 3 `_REDACTED.pdf` files listed here.
- [ ] Unticking a value in the preview leaves it visible in the output.
- [ ] The Leak Guard log shows caught leaks with counts only.
- [ ] Export writes both files and reveals them.
