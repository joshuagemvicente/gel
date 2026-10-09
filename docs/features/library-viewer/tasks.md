# U3 · Library and viewer — Tasks

Status: `[x]` done and verified · `[~]` built, not verified · `[ ]` not started.

- [x] **T1 File list.** `LibraryView` listing `Store.shared.documents()` with type filter, name search, multi-selection, indexing progress from `AppState`. Files: `Gel/Gel/Library/LibraryView.swift`.
  **Verify:** with demo data indexed, 58 files show; the Scans filter shows only images and image-only PDFs.
- [~] **T2 Viewer.** `DocumentViewer` (`NSViewRepresentable` around `PDFView`) for PDFs and images (one-page document from the image); text view for DOCX/TXT.
  **Verify:** open one file of each kind from `demo-data/HR Files`.
- [x] **T3 Citation highlight.** `highlight(citation:)`: go to page; text page → `selection(for:)` lines → annotations; OCR page/image → `PageLine` overlap → annotations; clear previous highlights; scroll into view. Triggered by `AppState.pendingCitation`.
  **Verify:** from the launcher, chip for Reyes opens page 2 with the payroll line highlighted; a citation on a scan JPG highlights the right lines.
- [~] **T4 Redact entry point.** "Redact n files" button → presents the redactions-module redact sheet with the selected URLs.
  **Verify:** selecting 3 files shows "Redact 3 files" and opens the sheet.
- [~] **T5 Empty states and reveal.** States from [design.md](design.md); context menu "Reveal in Finder".
  **Verify:** fresh `GEL_HOME` shows "No files yet"; Reveal opens Finder at the file.

Done when: all [spec.md](spec.md) acceptance criteria are observed passing.
