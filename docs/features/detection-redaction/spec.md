# F4 · Detection and redaction — Spec

**Goal:** find personal data reliably and remove it so it can't be recovered, erring toward redacting too much.

## Detection layers

| Layer | Catches | How | Network |
| --- | --- | --- | --- |
| 1 Patterns | IDs, phones, emails, salaries/amounts, accounts, cards, birth dates, labelled addresses | Regexes from the active [packs](../packs/spec.md); optional capture `group`; `luhn` validator for cards | none |
| 2 Names | People's names (2+ words or ≥ 6 chars) | Apple `NLTagger` `.nameType`, `.joinNames`, run on the text **and** on a title-cased copy (ALL-CAPS words → Title Case, same offsets) because the tagger misses all-caps names; then **name propagation**: any run of 2–4 capitalized words/initials in the same text that shares ≥ 2 name parts (≥ 3 letters) with a found name — or with an email's local part (`jasmine.tolentino@…`) — is also a NAME (catches "Jerome Q. Ramos" after "JEROME QUIAMBAO RAMOS"); plus core-pack patterns for honorifics (`Mr./Ms./Mrs./Dr./Engr./Atty. <Name>`) and labels (`Name:`, `Full name:`, split form fields `LAST NAME` / `FIRST NAME` / `MIDDLE NAME` with the value on the next line); pattern-found names also seed propagation | none |
| 3 Context | Addresses, salary context, health info, anything 1–2 missed | LLM returns `{"items":[{"text","type"}]}`; texts located in the original by case-insensitive search; input split into 2,500-char pieces | local first; falls back to the cloud **only on text already redacted by layers 1–2** |

- `detectFast` = layers 1+2 (instant; used by Leak Guard and the cloud gate). `detectFull` = all three (used for file redaction and the preview).
- **Merge:** overlapping findings keep the longest span; on equal length a specific type beats a generic one (`PHONE`, `AMOUNT`, `NAME`, `OTHER` are generic), then the lower layer wins.
- **Scans:** OCR reads ₱ as `P` and may use `.` as the thousands separator; packs include `P18.000.00`-style patterns.
- **Summary text:** `PIIDetector.summary` → e.g. "3 government ID numbers, 1 salary, 1 address" (category order: government ID, salary, bank account, card, money, address, birth date, health, contact, name, other).

## Redaction outputs

- **Placeholder text:** `Redactor.redactText` replaces each finding with a consistent token per value (`[SSS_1]` every time the same SSS number appears). The token → value mapping stays in memory only.
- **Cloud gate:** `Redactor.cloudGate(text)` = `detectFast` over **every installed pack** (not the active ones) + strict names + bare dates + placeholders. Takes no pack argument on purpose. Used for every cloud request, including the layer-3 fallback ([model-fallback](../model-fallback/spec.md) → Strict cloud gate, D-072).
- **Burned-in PDF:** every page rendered at 2×; boxes found via PDFKit selections (text pages) or Vision word boxes (`VNRecognizedText.boundingBox(for:)`, scans); black boxes (3 pt padding) flattened; written as a new **image-only** PDF to `<source folder>/Redacted/<name>_REDACTED.pdf`. Images → same, as a one-page PDF. DOCX/TXT → `<name>_REDACTED.txt` with placeholders that keep each finding's type (`[SSS_1]`, not `[OTHER_1]`).
- **Preview first:** the app shows findings grouped by category with checkboxes before writing; unticked values are kept (`keep:` set, matched case-insensitively).
- Each redaction logs a `redaction` event plus `redaction_item` counts per category, and a `redactions` row (source, output, counts).

## Output naming and DOCX types (E6, E7)

- Redaction never overwrites: if `<name>_REDACTED.pdf` exists, the output is `<name>_REDACTED-2.pdf`, `-3`, …
- DOCX/TXT outputs keep each finding's real type in placeholders (`[SSS_1]`, `[NAME_2]`), never `[OTHER_n]`.

## Every page is OCR-checked when redacting (Q1)

Burned-in redaction boxes come from **both** the PDFKit text layer and Vision OCR on every page, so a scan with a small text stamp can't slip through.

## IDs inside longer spans (Q3)

- Label patterns (e.g. `Address:`) stop at two or more spaces or at the next field label (`SSS`, `TIN`, `PhilHealth`, `Pag-IBIG`, `Tel`, `Mobile`, `Email`).
- When a government ID sits inside a longer non-ID finding, the ID is kept as its own finding and the longer span is cut to end before it, so block-mode policy and counts see the ID.

## Names in "SURNAME, First M." order (Q2)

Core pack adds `SURNAME, Given M.` / `Surname, Given` patterns (common in Philippine forms and lists).

## Acceptance criteria

- [ ] Layer 1 finds 100% of the SSS, TIN, PhilHealth, Pag-IBIG, PhilSys, passport, driver's license and card values in `ground_truth.json` for text-layer files (scripted check against the ground truth).
- [ ] Searching a redacted PDF's text with PDFKit returns nothing (image-only output), and none of the source's ground-truth values appear in OCR of the redacted output.
- [ ] Redacting a 5-page scan takes under 10 s without the LLM pass, under 30 s with it.
- [ ] With Ollama stopped and no cloud configured, `detectFull` still returns layer 1–2 findings (no crash, no hang beyond the timeout).
