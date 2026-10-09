# F1 · Indexing — Spec

**Goal:** everything in the user's chosen folder becomes searchable, offline, including scanned paper.

## Behaviour

- **Scope:** one folder chosen at first launch (Settings → HR Files folder). Subfolders included. Files under any folder named `Redacted` are skipped (Gel's own outputs). Hidden files skipped.
- **File types:** PDF (`.pdf`), images (`.jpg .jpeg .png .heic .tif .tiff`), Word (`.docx`), text (`.txt .md`).
- **Text:** PDF pages with ≥ 20 non-space characters use the PDFKit text layer. Other PDF pages are rendered at 2× and read with Vision OCR (`.accurate`, language correction on, `en-US` plus any `fil*` language Vision supports). Images are OCR'd. DOCX via `NSAttributedString(.officeOpenXML)` as one page.
- **OCR geometry:** each OCR line keeps its normalized bounding box (bottom-left origin) and its start offset in the page text, so citations and redactions can be drawn on scans.
- **Chunks:** ~700 characters, 120 overlap, breaking at a newline or space in the last 30% of the window. Offsets are UTF-16 (match `NSString` and PDFKit).
- **Embeddings:** `bge-m3` through Ollama `/api/embed`, batches of 16, input prefixed `File: <name> (page n)\n`, vectors L2-normalized.
- **Incremental:** a file is re-indexed only when its modification date changed; deleted files are pruned.
- **Watching:** while the app runs, rescan the folder every 5 s (cheap: compares modification dates) and index anything new or changed.
- **Progress:** the app shows "Indexing n of m · <file>" while running.

## Acceptance criteria

- [ ] `gelcli index "demo-data/HR Files"` indexes all 58 files without errors, in under 3 minutes on the M2.
- [ ] OCR'd text from at least one scan JPG and one image-only PDF contains a planted value from `ground_truth.json`.
- [ ] Re-running `gelcli index` immediately reports 0 files indexed.
- [ ] A file copied into the folder while the app runs becomes searchable within 10 s.
- [ ] Indexing works with Wi-Fi off (Ollama local).
