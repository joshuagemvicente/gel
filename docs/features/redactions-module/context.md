# U8 · Redactions & Leak Guard module — Context

## Why it exists

Demo step 3 (select three resumes → Redact → preview → burned-in PDFs) runs through this module's redact flow, and step 4 ends with **Export report** for the DPO, the B2B proof point. It serves **Problem & Usefulness (25%)** for the HR buyer and the WhiteCloak polish bar.

## Where it sits

- **Upstream:** library-viewer (selected file URLs), detection-redaction (`PIIDetector.detectFull`, `Redactor.redactFile`), leak-guard (logs `leak_caught`/`leak_item`), policy-dpo-report (`DPOReport.export`).
- **Downstream:** home (stats), the Finder (outputs).

## Current state

- Nothing built in the app target.
- Engine ready: `TextExtraction.extract(url:kind:)`, `PIIDetector.shared.detectFull(_:packs:) async -> FullResult` (findings + `llmProvider`), `Redactor.redactFile(_:findings:keep:) throws -> FileResult` (output URL + counts), `Store.saveRedaction/redactions()`, `Store.logEvent`, `DPOReport.export(since:organization:) throws -> [URL]`.

## Facts and gotchas

- **The redact flow must log:** one `redaction` event per file, `redaction_item` events per category with counts, and a `saveRedaction` row. `Redactor.redactFile` does not log by itself; the UI calls `Store` after success.
- Layer 3 on a resume takes a few seconds on the local 4B model (text split into 2,500-character pieces); show progress per file.
- Outputs go to `<source folder>/Redacted/<name>_REDACTED.pdf` (DOCX/TXT → `.txt`); the indexer skips `Redacted` folders.
- `keep` is a set of lowercased values the user un-ticked.

## Related docs

[spec](spec.md) · [design](design.md) · [tasks](tasks.md) · [detection-redaction](../detection-redaction/spec.md) · [policy-dpo-report](../policy-dpo-report/spec.md) · [leak-guard](../leak-guard/spec.md)
