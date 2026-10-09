# F4 · Detection and redaction — Tasks

Legend: `[x]` done and verified · `[~]` built, not verified end-to-end · `[ ]` not started. Commands: `cd Gel`, `export GEL_HOME=/tmp/gel-dev`, `CLI=build/Build/Products/Debug/gelcli`.

- [x] **T1 Layer 1 patterns + Luhn + merge.** Files: `GelCore/PII/PIIDetector.swift`, `GelCore/Resources/pack_*.json`. **Verify:** unit tests `testPhilippineGovernmentIDs`, `testPhilSysWinsOverPagIbigShape`, `testPersonalIDsAndMoney`, `testCardNeedsLuhn`, `testCoreContactsAlwaysOn` pass.
- [x] **T2 Placeholders, cloud gate, summary.** Files: `GelCore/PII/Redactor.swift`, `PIIDetector.swift`. **Verify:** `testRedactTextUsesConsistentPlaceholders`, `testCloudSafeRemovesIDs`, `testSummary` pass.
- [x] **T3 Layer 2 names.** `NLTagger` personal names. **Verify:** `$CLI detect --packs hr "Employee: Maria Clara Santos, Payroll Officer"` lists a `NAME` finding for the person and none for the title.
- [x] **T4 Ground-truth recall check.** Write `scripts/check_detection.swift` (or a `GelCoreTests` test reading `demo-data/ground_truth.json`) that runs layer 1 on every text-layer file and reports recall per type. Files: new script/test. **Verify:** 100% recall for SSS, TIN, PHILHEALTH, PAGIBIG, PHILSYS, PASSPORT, DRIVERS_LICENSE, CARD on text-layer files; fix packs until it does.
- [x] **T5 Layer 3 (LLM).** Files: `PIIDetector.swift`. **Verify:** `$CLI detect --full --file "../demo-data/HR Files/201 Files/<any>.pdf"` prints `LLM pass: local` and at least one `L3` address or salary finding.
- [x] **T6 Burned-in redaction (text PDF + scan + image).** Files: `Redactor.swift`. **Verify:** `$CLI redact` on one resume PDF, one image-only PDF and one JPG; open outputs in `Redacted/`; PDFKit text of each output is empty and OCR of each output contains none of that file's ground-truth values.
- [x] **T7 Degraded mode.** **Verify:** stop Ollama, unset `GEL_CLOUD_*`, run T5's command → prints `LLM pass: unavailable` with layer 1–2 findings in under 30 s.
- [ ] **T8 Caller logging contract.** The redact flow (app) logs `redaction` + `redaction_item` per category and `Store.saveRedaction`. Owned by [redactions-module](../redactions-module/spec.md). **Verify:** after redacting, `$CLI stats` shows the redaction count.
- [x] **T9 Measure.** Time T6 on a 5-page scan with and without layer 3; record in [decisions](../../project/decisions.md).

Done when: all [spec.md](spec.md) acceptance criteria observed passing.
- [ ] **T10 E6/E7 naming + DOCX types.** **Verify:** redact the same file twice → `_REDACTED.pdf` and `_REDACTED-2.pdf`; redacted DOCX text shows `[SSS_1]`-style tokens.
