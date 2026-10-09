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

## Dummy replacement (R5, D-073)

A second treatment next to black-out, chosen per redaction in the review sheet.

- **Control:** a segmented picker above the findings list: **Black out** | **Replace with dummy data**. Switching re-renders every After page live; the header reads "Gel will replace **15 of 17** items in 3 files with dummy data" and the button "Replace 15 items · Save 3 copies".
- **Fakes** come from `DummyData`: type-aware and random, never derived from the original, one fake per distinct value within a file (the same SSS number becomes the same fake everywhere). IDs, phones, accounts and cards keep their exact shape with random digits; names come from a fixed fictional Tagalog word-name list that does not overlap the demo files; emails, addresses, dates and amounts get plausible values in the original's format; anything else becomes lorem ipsum of similar length.
- **Pages (PDF, scans):** each box is filled white and the fake is drawn in a system font fitted to the box height, shrunk then truncated with an ellipsis when too wide. A value wrapped over several boxes has its fake split across them in reading order. The saved copy is still an image-only PDF.
- **Text (DOCX, TXT):** fakes replace the values instead of `[SSS_1]` placeholders.
- **Consistency:** the sheet fixes the replacement map when the scan finishes and passes the same map to the preview and to `redactFile`, so the saved copy equals After.
- **Naming and records:** outputs keep `_REDACTED`; the `redactions` row stores the mode and the Redactions list shows "blacked out" or "dummy data" before the counts.
- **Leak Guard:** Settings › Hotkeys gains **Paste dummy data instead of placeholders** (off by default). When on, ⌥⌘V and block mode put fakes on the clipboard instead of placeholders. The cloud gate always uses placeholders.

## Add something Gel missed (R6, D-073)

A text field next to the mode picker: "Add something Gel missed: a value, or what to look for", with **Find**.

- Every entry runs on **every file in the sheet**: first every case-insensitive literal match of the text (instant, offline), then the **local** model with the instruction (`PIIDetector.promptFindings`, 2,500-char pieces, 25 s each). The cloud is never used for this; if the local model is unavailable the note says so and only exact matches are added.
- Results join the findings as an **Added by you** group (`category = "added by you"`): ticked, boxed on Before/After, written only on Save. Literal matches carry the label "exact match"; model results keep the model's type so dummy fakes stay type-aware.
- The note under the field reports the outcome: "Added 3 items for “…”. They're ticked below; untick any you want to keep." / "Nothing matched “…”." / "…The local AI is unavailable, so only exact matches were added."
- Nothing is remembered between redactions. "Save as rule" (a custom pack entry) is post-hackathon.

### Acceptance criteria (R5, R6)

- [ ] Dummy mode on a demo resume: the saved PDF's OCR contains none of the ground-truth values for that file, every box shows readable fake text, and the DOCX output has no `[` placeholders.
- [ ] Switching the picker changes After without re-running OCR; Save produces exactly what After showed.
- [ ] Typing a company name that the scan didn't flag adds it as "Added by you" on every file that contains it, with boxes; unticking it keeps it visible in the output.
- [ ] With Ollama stopped, a description still adds literal matches and the note explains the model was unavailable.
- [ ] With the Settings toggle on, ⌥⌘V pastes fakes (no `[` in the pasted text); off, it pastes placeholders.
