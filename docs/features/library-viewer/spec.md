# U3 · Library and viewer — Spec

**Goal:** browse every indexed file, see citations highlighted on the page (including scans), and start redaction.

## Behaviour

- **Layout:** two panes. Left: file list (name, type badge PDF/Scan/DOCX/Text, page count, an "OCR" tag when pages were read by OCR); type filter (All, PDF, Scans, DOCX) and a name search field; indexing progress at the top while running. Right: the viewer.
- **Viewer:** `PDFView` (auto-scales, continuous scroll).
  - PDF → open the file.
  - Image → a one-page `PDFDocument` built from the image (`PDFPage(image:)`).
  - DOCX/TXT → a scrollable text view with the cited range highlighted.
- **Citation highlight:** open at the cited page, then:
  - text page → `page.selection(for: NSRange(start, length))` → a highlight `PDFAnnotation` per line (yellow, 0.35 alpha), scrolled into view;
  - OCR page or image → highlight annotations from the stored `PageLine` rects whose `[start, start+text.count)` overlaps the citation range (convert normalized bottom-left rects to page coordinates: `x * width + minX`, `y * height + minY`).
  - Opening another file or citation clears previous highlights.
- **Multi-select + Redact:** ⌘-click/shift-click to select files; a **Redact** button runs the redact flow in the redactions-module spec.
- **Reveal:** context menu "Reveal in Finder".

## Acceptance criteria

- [ ] All indexed demo files appear; the Scans filter shows only image files and image-only PDFs.
- [ ] Opening a citation highlights the right passage on a text PDF and on a scan, in under 1 s.
- [ ] Selecting 3 files enables **Redact** with "Redact 3 files".
