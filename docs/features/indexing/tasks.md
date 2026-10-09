# F1 · Indexing — Tasks

Legend: `[x]` done and verified · `[~]` built, not verified end-to-end · `[ ]` not started. Commands assume `cd Gel`, `export GEL_HOME=/tmp/gel-dev`, `CLI=build/Build/Products/Debug/gelcli` ([conventions](../../project/conventions.md)).

- [x] **T1 Chunker.** UTF-16 chunks of ~700 chars, 120 overlap, break at newline/space. Files: `GelCore/Index/TextExtraction.swift`. **Verify:** unit test `testChunkerCoversText` passes.
- [x] **T2 Text extraction + OCR.** PDF text layer, OCR fallback, images, DOCX, TXT; OCR line geometry. Files: `TextExtraction.swift`, `Models.swift`. **Verify:** `$CLI detect --file "../demo-data/HR Files/Scans/<any>.jpg"` prints OCR'd text containing a value listed for that file in `ground_truth.json`; same for one image-only PDF.
- [x] **T3 Embedder.** Batches of 16 to `/api/embed`, normalized. Files: `Indexer.swift`. **Verify:** indexing completes; `$CLI search "payroll"` returns ranked hits with scores.
- [x] **T4 Store + incremental indexing.** Transactional save, skip unchanged, prune missing. Files: `Store.swift`, `Indexer.swift`. **Verify:** `$CLI index "../demo-data/HR Files"` reports 58 files in < 3 min; running it again reports 0; `$CLI stats` shows 58 documents.
- [ ] **T5 Folder rescan in the app.** Every 5 s while the app runs, call `Indexer.index(folder:progress:)` when `pending(in:)` is non-empty; publish `IndexProgress` to `AppState`. Files: `Gel/` app target (app-shell). **Verify:** copy a PDF into the folder with the app open; it's searchable within 10 s.
- [ ] **T6 Offline check.** **Verify:** Wi-Fi off, delete `$GEL_HOME`, re-run T4's index command; it succeeds.
- [x] **T7 Record numbers.** Add the measured index time and chunk count to [decisions](../../project/decisions.md).

Done when: all [spec.md](spec.md) acceptance criteria observed passing.
- [x] **T8 E2/E3/E8 folder safety.** Skip prune when the folder is missing; drop documents outside a newly chosen folder; collect unreadable files. **Verify:** rename the folder → Library keeps files and shows "Folder not found"; rename back → recovers; a corrupt PDF shows in "couldn't be read".
- [x] **T9 Q1 OCR short text layers.** **Verify:** a PDF made of a scan image + one small text stamp is searchable by an SSS number on it.
