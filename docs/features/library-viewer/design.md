# U3 · Library and viewer — Design

## Layout

```
┌ Library ──────────────────────────────────────────────────────────────┐
│ [All | PDF | Scans | DOCX]   🔍 Search files      Indexing 12 of 58 ▓▓░ │
├─────────────────────────────┬─────────────────────────────────────────┤
│ ▢ Resume_REYES.pdf   PDF 2p │                                         │
│ ▣ Santos_Rodel_…     PDF 1p │        ┌───────────────────────┐        │
│ ▣ CV - Patricia …    PDF 2p │        │  page 2               │        │
│ ▢ payslip_scan_03    Scan OCR│        │  ████ highlighted ████ │        │
│ …                           │        │                       │        │
│                             │        └───────────────────────┘        │
│ [ Redact 2 files ]          │   Resume_REYES.pdf · page 2 of 2        │
└─────────────────────────────┴─────────────────────────────────────────┘
```

- File list 320 pt wide; rows 36 pt: name (truncate middle), type badge (PDF / Scan / DOCX / Text), page count, an `OCR` tag in textSecondary when `hasOCR`.
- Viewer background `canvas`; page shadow subtle; footer caption with file name and "page n of m".
- The **Redact** button sits pinned at the bottom of the list, accent-filled, disabled until a selection exists; label "Redact n file(s)".

## States

| State | Shows |
| --- | --- |
| Nothing indexed | EmptyState `books.vertical`: "No files yet" · "Choose a folder in Settings" (button) |
| No file selected | EmptyState: "Select a file, or click a citation in the launcher" |
| Indexing | Progress capsule in the header: "Indexing 12 of 58" |
| DOCX/TXT | Text view (13 pt, 1.4 line height) with the cited range on accentSoft |

## Highlight style

Yellow (`NSColor.systemYellow`) at 0.35 alpha for PDF annotations, so the text stays readable; the viewer scrolls the first highlight into the vertical center.
