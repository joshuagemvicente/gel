# F1 · Indexing — Context

## Why it exists

Everything Gel does starts from the index. HR staff keep resumes, 201 files, payslips and scanned paper in one folder; Gel must read all of it, including scans, without sending anything off the Mac. It serves the **Local AI implementation** (25%) and **Technical execution** (20%) criteria ([context](../../project/context.md)). Demo moment: the scanned resume that still gets cited and highlighted.

## Where it sits

- **Upstream:** the folder chosen in [settings](../settings/spec.md) or [onboarding](../onboarding/spec.md); Ollama running with `bge-m3`.
- **Downstream:** [query-citations](../query-citations/spec.md) (vector + keyword search, page/offset citations), [library-viewer](../library-viewer/spec.md) (file list, OCR line boxes for highlights), [home](../home/spec.md) (index stats).

## Current state

Built in `Gel/GelCore/Index/`:

| File | What's there |
| --- | --- |
| `TextExtraction.swift` | `TextExtraction.extract(url:kind:)` (PDF text layer, OCR fallback at < 20 chars, images, DOCX, TXT), `render(page:scale:)`, `loadImage(url:)`; `OCR.recognizeLines/recognize`; `Chunker.chunks(for:target:overlap:)` |
| `Indexer.swift` | `Embedder` (Ollama `/api/embed`, L2-normalized, `keep_alive` 60m); `Indexer` (`supportedFiles`, `pending`, `pruneMissing`, `index(folder:progress:)`, `index(file:)`) |
| `Store.swift` | SQLite schema, `save(path:kind:modified:pages:chunks:)` in one transaction, page/chunk reads, lazy vector cache |
| `Models.swift` | `DocKind`, `DocumentRecord`, `PageContent`, `PageLine`, `Chunk` |

`gelcli index <folder>` drives it. **Missing:** the app-side 5 s folder rescan and progress UI (owned by [app-shell](../app-shell/spec.md) and [library-viewer](../library-viewer/spec.md)); end-to-end verification on `demo-data/` has not been run yet.

## Facts and gotchas

- Dataset: `demo-data/HR Files` = 58 files (20 resumes, 15 201 files, 10 payslips, 3 DOCX, 10 scans: 5 JPG + 5 image-only PDFs). `ground_truth.json` lists every planted value with type and page ([architecture](../../project/architecture.md) → Demo data).
- The 5 image-only PDFs have **no text layer** by design; they exercise the OCR path.
- OCR reads `₱` as `P` and may print `18.000.00`; detection handles that, indexing stores OCR text as-is.
- `bge-m3` returns 1024-dim vectors. Embedding inputs are prefixed `File: <name> (page n)\n`; stored chunk text is raw.
- Vision on macOS 15.8: `.accurate` level; Tagalog (`fil*`) is added only if `supportedRecognitionLanguages()` lists it.
- Folders named `Redacted` are skipped so Gel's own outputs aren't re-indexed.
- DOCX and TXT are one "page" (page index 0).

## Related

[spec](spec.md) · [tasks](tasks.md) · [interfaces](interfaces.md) · [architecture](../../project/architecture.md) · [decisions D-016](../../project/decisions.md)
