# U3 · Library and viewer — Context

## Why it exists

Demo step 2 is the trust moment: click Reyes's citation and the main window opens on **page 2** of her resume with the payroll line highlighted. That answers the judges' "a 4B model makes mistakes" objection: every claim is checkable. Step 3 starts here too: select three resumes → **Redact** ([demo script](../../project/demo-and-submission.md)).

## Where it sits

- **Upstream:** indexing (documents, pages, OCR line boxes in `Store`), query-citations (`Citation` with UTF-16 start/length), app-shell (`AppState.pendingCitation`, module switching).
- **Downstream:** redactions-module (the redact flow starts from the selection here).

## Current state

- Nothing built in the app target.
- Engine data ready: `Store.shared.documents() -> [DocumentRecord]` (path, kind, pageCount, hasOCR), `Store.shared.page(docId:page:) -> PageContent?` (text + `lines: [PageLine]?` for OCR pages), `Citation` (docId, path, page, start, length).

## Facts and gotchas

- **Text pages:** `PDFPage.selection(for: NSRange)` takes the range in the page's `string` (UTF-16) coordinates, the same offsets the chunker stored. Use `selection.selectionsByLine()` and add one highlight annotation per line.
- **OCR pages:** a chunk range maps to lines by offset: highlight each `PageLine` with `[start, start + (text as NSString).length)` overlapping `[c.start, c.start + c.length)`. Convert the normalized rect: `x = r.minX * bounds.width + bounds.minX`, `y = r.minY * bounds.height + bounds.minY` (both bottom-left origin, so no flip).
- **Image files:** `PDFPage(image:)` makes a page whose bounds match the image's point size; the normalized rects still apply.
- **Image-only PDFs** in `demo-data/HR Files/Scans/` have no text layer, so they always take the OCR path.
- Opening a large PDF on the main thread is fine for this dataset (1–3 pages per file).

## Related docs

[spec](spec.md) · [design](design.md) · [tasks](tasks.md) · [indexing](../indexing/spec.md) · [query-citations](../query-citations/spec.md)
