import SwiftUI
import PDFKit
import GelCore

enum LibraryFilter: String, CaseIterable, Identifiable {
    case all = "All", pdf = "PDF", scans = "Scans", docx = "DOCX"
    var id: String { rawValue }

    func matches(_ d: DocumentRecord) -> Bool {
        switch self {
        case .all: return true
        case .pdf: return d.kind == .pdf && !d.hasOCR
        case .scans: return d.kind == .image || (d.kind == .pdf && d.hasOCR)
        case .docx: return d.kind == .docx || d.kind == .text
        }
    }
}

struct LibraryView: View {
    @EnvironmentObject var state: AppState
    @State private var documents: [DocumentRecord] = []
    @State private var filter: LibraryFilter = .all
    @State private var search = ""
    @State private var selection = Set<Int64>()
    @State private var shown: DocumentRecord?
    @State private var highlight: Citation?
    @State private var redactURLs: [URL]?

    private var filtered: [DocumentRecord] {
        documents.filter { filter.matches($0) && (search.isEmpty || $0.name.localizedCaseInsensitiveContains(search)) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                ModuleHeader(title: "Library")
                Spacer()
                if let p = state.indexProgress {
                    Text("Indexing \(p.done + 1) of \(p.total)").font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                    ProgressView(value: Double(p.done), total: Double(max(p.total, 1))).frame(width: 90)
                }
            }
            HStack {
                Picker("", selection: $filter) { ForEach(LibraryFilter.allCases) { Text($0.rawValue).tag($0) } }
                    .pickerStyle(.segmented).frame(width: 280).labelsHidden()
                TextField("Search files", text: $search).textFieldStyle(.roundedBorder).frame(width: 220)
                Spacer()
            }
            if documents.isEmpty {
                EmptyStateView(symbol: "books.vertical", title: "No files yet", hint: "Choose a folder in Settings and Gel will read it on this Mac.")
                    .overlay(alignment: .bottom) {
                        Button("Open Settings") { state.selectedModule = .settings }.padding(.bottom, 80)
                    }
            } else {
                HStack(spacing: 14) {
                    fileList.frame(width: 330)
                    viewer
                }
            }
        }
        .padding(28)
        .onAppear(perform: reload)
        .onChange(of: state.documentsVersion) { _, _ in reload() }
        .onChange(of: state.pendingCitation) { _, _ in consumeCitation() }
        .sheet(item: Binding(get: { redactURLs.map { RedactRequest(urls: $0) } }, set: { redactURLs = $0?.urls })) { req in
            RedactSheet(urls: req.urls)
        }
    }

    private var fileList: some View {
        VStack(spacing: 0) {
            List(filtered, selection: $selection) { doc in
                HStack(spacing: 8) {
                    Image(systemName: doc.kind == .image ? "photo" : (doc.kind == .docx ? "doc.text" : "doc.richtext"))
                        .foregroundStyle(Theme.textSecondary).frame(width: 16)
                    Text(doc.name).lineLimit(1).truncationMode(.middle).font(.system(size: 12.5))
                    Spacer()
                    if doc.hasOCR { Text("OCR").font(.system(size: 9.5, weight: .semibold)).foregroundStyle(Theme.textSecondary) }
                    Text("\(doc.kind.label) \(doc.pageCount)p").font(.system(size: 10.5)).foregroundStyle(Theme.textSecondary)
                }
                .tag(doc.id)
                .contextMenu {
                    Button("Reveal in Finder") { NSWorkspace.shared.activateFileViewerSelecting([doc.url]) }
                }
            }
            .listStyle(.inset)
            .scrollContentBackground(.hidden)
            .onChange(of: selection) { _, new in
                if new.count == 1, let id = new.first, let d = documents.first(where: { $0.id == id }) {
                    highlight = nil
                    shown = d
                }
            }
            Divider()
            Button {
                redactURLs = documents.filter { selection.contains($0.id) }.map(\.url)
            } label: {
                Text(selection.isEmpty ? "Select files to redact" : "Redact \(selection.count) file\(selection.count == 1 ? "" : "s")")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent).tint(Theme.accent)
            .disabled(selection.isEmpty)
            .padding(10)
        }
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.hairline))
    }

    @ViewBuilder private var viewer: some View {
        if let doc = shown {
            VStack(spacing: 6) {
                DocumentViewer(document: doc, citation: highlight)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.hairline))
                Text(highlight.map { "\(doc.name) · page \($0.page + 1) of \(doc.pageCount)" } ?? doc.name)
                    .font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
            }
        } else {
            EmptyStateView(symbol: "doc.text.magnifyingglass", title: "Select a file",
                           hint: "Or click a citation in the launcher to open the exact page.")
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func reload() {
        documents = Store.shared.documents()
        consumeCitation()
    }

    private func consumeCitation() {
        guard let c = state.pendingCitation else { return }
        state.pendingCitation = nil
        filter = .all
        search = ""
        if let d = Store.shared.document(id: c.docId) {
            selection = [d.id]
            shown = d
            highlight = c
        }
    }
}

struct RedactRequest: Identifiable {
    let id = UUID()
    let urls: [URL]
}

/// PDFKit viewer for PDFs and images (shown as a one-page PDF), a text view for DOCX/TXT, with citation highlights.
struct DocumentViewer: NSViewRepresentable {
    var document: DocumentRecord
    var citation: Citation?

    func makeNSView(context: Context) -> NSView {
        let container = NSView()
        return container
    }

    func updateNSView(_ container: NSView, context: Context) {
        let key = "\(document.id)-\(citation?.id ?? -1)-\(citation?.start ?? -1)"
        if context.coordinator.key == key { return }
        context.coordinator.key = key
        container.subviews.forEach { $0.removeFromSuperview() }

        switch document.kind {
        case .docx, .text:
            let scroll = NSTextView.scrollableTextView()
            let tv = scroll.documentView as! NSTextView
            tv.isEditable = false
            tv.textContainerInset = NSSize(width: 24, height: 24)
            let text = Store.shared.pages(docId: document.id).map(\.text).joined(separator: "\n")
            let attr = NSMutableAttributedString(string: text, attributes: [.font: NSFont.systemFont(ofSize: 13), .foregroundColor: NSColor.textColor])
            if let c = citation, c.start + c.length <= (text as NSString).length {
                let r = NSRange(location: c.start, length: c.length)
                attr.addAttribute(.backgroundColor, value: NSColor.systemYellow.withAlphaComponent(0.35), range: r)
                tv.textStorage?.setAttributedString(attr)
                tv.scrollRangeToVisible(r)
            } else {
                tv.textStorage?.setAttributedString(attr)
            }
            add(scroll, to: container)
        case .pdf, .image:
            let view = PDFView()
            view.autoScales = true
            view.displayMode = .singlePageContinuous
            view.backgroundColor = NSColor(hex: 0xEFECE6)
            let pdf: PDFDocument?
            if document.kind == .image {
                let doc = PDFDocument()
                if let image = NSImage(contentsOf: document.url), let page = PDFPage(image: image) { doc.insert(page, at: 0) }
                pdf = doc
            } else {
                pdf = PDFDocument(url: document.url)
            }
            view.document = pdf
            add(view, to: container)
            if let c = citation, let pdf, let page = pdf.page(at: c.page) {
                Self.highlight(c, on: page, in: view)
            }
        }
    }

    private func add(_ view: NSView, to container: NSView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            view.topAnchor.constraint(equalTo: container.topAnchor),
            view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
    }

    /// Text pages: PDFKit selection from the chunk's UTF-16 range. OCR pages and images: the stored OCR line boxes
    /// that overlap the range (normalized, bottom-left origin → page coordinates).
    static func highlight(_ c: Citation, on page: PDFPage, in view: PDFView) {
        let bounds = page.bounds(for: .mediaBox)
        var rects: [CGRect] = []
        let stored = Store.shared.page(docId: c.docId, page: c.page)
        if let lines = stored?.lines {
            let lo = c.start, hi = c.start + c.length
            for line in lines {
                let ls = line.start, le = line.start + (line.text as NSString).length
                if ls < hi && le > lo {
                    rects.append(CGRect(x: line.rect.minX * bounds.width + bounds.minX, y: line.rect.minY * bounds.height + bounds.minY,
                                        width: line.rect.width * bounds.width, height: line.rect.height * bounds.height))
                }
            }
        } else if let text = page.string, c.start + c.length <= (text as NSString).length,
                  let sel = page.selection(for: NSRange(location: c.start, length: c.length)) {
            rects = sel.selectionsByLine().map { $0.bounds(for: page) }
        }
        for r in rects {
            let a = PDFAnnotation(bounds: r.insetBy(dx: -2, dy: -1), forType: .highlight, withProperties: nil)
            a.color = NSColor.systemYellow.withAlphaComponent(0.35)
            page.addAnnotation(a)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            if let first = rects.first {
                view.go(to: CGRect(x: first.minX, y: first.maxY + 120, width: 1, height: 1), on: page)
            } else {
                view.go(to: page)
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }
    final class Coordinator { var key = "" }
}
