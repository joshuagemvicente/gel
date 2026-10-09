# F4 · Detection and redaction — Context

## Why it exists

HR files are full of SSS, TIN, PhilHealth, Pag-IBIG and PhilSys numbers, salaries and addresses protected by the Data Privacy Act ([context](../../project/context.md)). Detection powers three things: redacted files to share (demo beat 3), the leak catch at the clipboard (beat 4), and the gate that keeps raw data out of the cloud fallback. Serves **Problem & usefulness** and **Innovation**.

## Where it sits

- **Upstream:** [packs](../packs/spec.md) (active patterns), [indexing](../indexing/spec.md) (`TextExtraction`, `OCR`), [model-fallback](../model-fallback/spec.md) (layer 3 via `completeJSON`).
- **Downstream:** [leak-guard](../leak-guard/spec.md) (`detectFast`, `summary`, `redactText`), [redactions-module](../redactions-module/spec.md) (preview + `redactFile`), [query-citations](../query-citations/spec.md) and [model-fallback](../model-fallback/spec.md) (`cloudSafe`), [policy-dpo-report](../policy-dpo-report/spec.md) (categories for block mode and reports).

## Current state

Built in `Gel/GelCore/PII/`:

- `PIIDetector.swift`: `PIIType`, `Pack`, `Finding`, `PackStore`; `PIIDetector.patternFindings` (layer 1, `luhn` validator), `nameFindings` (layer 2, `NLTagger`), `detectFast`, `detectFull` (layer 3 in 2,500-char pieces), `merge`, `summary`.
- `Redactor.swift`: `redactText` (placeholders + mapping + counts), `cloudSafe`, `outputURL`, `redactFile` (burned-in PDF for PDFs/scans/images; `.txt` for DOCX/TXT).
- Unit tests passing (10): government IDs, PhilSys-vs-Pag-IBIG merge, personal IDs and money, Luhn, core contacts, consistent placeholders, `cloudSafe`, summary (+ citations, chunker).
- `gelcli detect` and `gelcli redact` drive it.

**Missing:** ground-truth recall check, verification of burned-in outputs, layer-3 quality check, the preview UI and Redact button (app side). `redactFile` does **not** log events or `redactions` rows; the caller must (see [interfaces](interfaces.md)).

## Facts and gotchas

- OCR reads `₱` as `P` and may print `P18.000.00`; packs include that pattern ([decisions D-013](../../project/decisions.md)).
- Bank accounts in the dataset look like `###-####-###(##)` and often lack an "account" label; packs include the bare format.
- Pag-IBIG `####-####-####` is a prefix of PhilSys `####-####-####-####`: lookarounds plus longest-span merge resolve it.
- A GCash number is also a phone number: on equal spans, specific types beat `PHONE`/`AMOUNT`/`NAME`/`OTHER` ([D-014](../../project/decisions.md)).
- `NLTagger` misses some Filipino names and tags some job titles; layer 3 and the user's preview cover the gap.
- Layer 3 with the 4B model: keep inputs short (2,500 chars), ask for exact substrings, and locate them case-insensitively.
- DOCX redaction re-locates values and labels them all `OTHER`, so DOCX placeholders read `[OTHER_n]`.

## Related

[spec](spec.md) · [tasks](tasks.md) · [interfaces](interfaces.md) · [packs](../packs/spec.md)
