import SwiftUI
import GelCore

/// R4 review (docs/features/redactions-module/spec.md): Before | After pages side by side, findings underneath.
/// After is rendered by the same code that writes the saved copy (`Redactor.redactedImage`).
/// No running animations here: the pulse is a plain state flip (D-047).
struct RedactReview: View {
    struct FileItem: Identifiable, Equatable {
        var url: URL
        var findings: [Finding]
        var id: URL { url }
    }

    /// One unique value (case-insensitive) — the unit the user ticks and the unit the counts use.
    struct Item: Identifiable, Hashable {
        var key: String          // lowercased value, matches `keep`
        var value: String
        var label: String
        var category: String
        var files: [URL]
        var id: String { key }
    }

    /// Live counts for the sheet's header and button. `blackOut` = ticked values that will really be covered.
    struct Summary: Equatable {
        var blackOut = 0
        var total = 0
        var ready = false
    }

    let files: [FileItem]
    @Binding var unticked: Set<String>
    @Binding var summary: Summary
    var disabled = false

    private enum Preview {
        case loading
        case ready(pages: [Redactor.RenderedPage], after: [Int: CGImage])
        case unavailable
        case failed(String)
    }

    @State private var previews: [URL: Preview] = [:]
    @State private var selected: URL?
    @State private var page = 0
    @State private var pulse: String?
    @State private var afterGeneration = 0

    // MARK: - Derived

    var items: [Item] {
        var order: [String] = []
        var map: [String: Item] = [:]
        for f in files {
            for finding in f.findings {
                let key = finding.text.lowercased()
                if var existing = map[key] {
                    if !existing.files.contains(f.url) { existing.files.append(f.url) }
                    map[key] = existing
                } else {
                    order.append(key)
                    map[key] = Item(key: key, value: finding.text, label: finding.label, category: finding.category, files: [f.url])
                }
            }
        }
        return order.compactMap { map[$0] }
    }

    private var groups: [(category: String, items: [Item])] {
        Dictionary(grouping: items, by: \.category)
            .map { ($0.key, $0.value) }
            .sorted { $0.1.count != $1.1.count ? $0.1.count > $1.1.count : $0.0 < $1.0 }
    }

    private var current: URL? { selected ?? files.first?.url }

    private func count(for url: URL) -> Int {
        items.filter { $0.files.contains(url) && locatable($0, in: url) }.count
    }

    /// PDFs/images: only values with a box can be blacked out. DOCX/TXT (no preview): every value is replaced.
    private func locatable(_ item: Item, in url: URL) -> Bool {
        switch previews[url] {
        case .ready(let rendered, _): return rendered.contains { $0.boxes.contains { $0.value.lowercased() == item.key } }
        case .unavailable, .failed: return true
        case .loading, nil: return false
        }
    }

    private func locatable(_ item: Item) -> Bool { item.files.contains { locatable(item, in: $0) } }

    private var allLoaded: Bool {
        files.allSatisfy { f in
            if case .loading = previews[f.url] ?? .loading { return false }
            return true
        }
    }

    private func updateSummary() {
        let countable = items.filter(locatable)
        let new = Summary(blackOut: countable.filter { !unticked.contains($0.key) }.count, total: countable.count, ready: allLoaded)
        if new != summary { summary = new }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if files.count > 1 { fileTabs }
            pages
            Rectangle().fill(Theme.hairline).frame(height: 1)
            findingsList.frame(height: 190)
        }
        .onAppear {
            if selected == nil { selected = files.first?.url }
            // Render every file now: the counts depend on which values each page actually contains.
            for f in files { loadPreview(for: f.url) }
        }
        .onChange(of: selected) { _, _ in page = 0 }
        .onChange(of: unticked) { _, _ in refreshAfter(); updateSummary() }
        .onChange(of: allLoaded) { _, _ in updateSummary() }
    }

    private var fileTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(files) { f in
                    let on = f.url == current
                    Button { selected = f.url } label: {
                        HStack(spacing: 6) {
                            Text((f.url.lastPathComponent as NSString).deletingPathExtension).lineLimit(1)
                            Text("\(count(for: f.url))").font(.system(size: 10.5, weight: .semibold).monospacedDigit())
                                .padding(.horizontal, 5).padding(.vertical, 1)
                                .background(on ? Color.white.opacity(0.25) : Theme.hairline, in: Capsule())
                        }
                        .font(.system(size: 12, weight: on ? .semibold : .regular))
                        .foregroundStyle(on ? Color.white : Theme.textPrimary)
                        .padding(.horizontal, 10).frame(height: 26)
                        .background(on ? Theme.accentFill : Theme.card, in: Capsule())
                        .overlay(Capsule().strokeBorder(on ? Color.clear : Theme.hairline))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Pages

    @ViewBuilder private var pages: some View {
        switch current.flatMap({ previews[$0] }) ?? .loading {
        case .loading:
            placeholder { ProgressView().controlSize(.small); Text("Preparing the preview on this Mac…") }
        case .unavailable:
            placeholder {
                Image(systemName: "doc.text").font(.system(size: 22)).foregroundStyle(Theme.textSecondary)
                Text("Preview isn't available for Word files; the copy is saved as text with placeholders.")
            }
        case .failed(let message):
            placeholder {
                Image(systemName: "exclamationmark.triangle").font(.system(size: 22)).foregroundStyle(Theme.danger)
                Text("Couldn't preview \(current?.lastPathComponent ?? "this file"). You can still save the copy.")
                Text(message).font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
            }
        case .ready(let rendered, let after):
            if rendered.isEmpty {
                placeholder { Text("Nothing to preview in this file.") }
            } else {
                let p = rendered[min(page, rendered.count - 1)]
                VStack(spacing: 8) {
                    HStack {
                        paneTitle("Before", "your original, unchanged")
                        Spacer(minLength: 16)
                        paneTitle("After", "exactly what the saved copy will look like")
                    }
                    ScrollViewReader { proxy in
                        ScrollView(.vertical) {
                            HStack(alignment: .top, spacing: 16) {
                                pageImage(p.original, size: p.size, boxes: p.boxes, before: true)
                                pageImage(after[p.index] ?? p.redacted, size: p.size, boxes: p.boxes, before: false)
                            }
                            .padding(2)
                        }
                        .background(Theme.canvas, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .onChange(of: pulse) { _, key in
                            guard let key, p.boxes.contains(where: { $0.value.lowercased() == key }) else { return }
                            proxy.scrollTo("box-\(key)", anchor: .center)
                        }
                    }
                    if rendered.count > 1 { pageArrows(count: rendered.count) }
                }
            }
        }
    }

    private func placeholder<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        VStack(spacing: 8, content: content)
            .font(.system(size: 12.5)).foregroundStyle(Theme.textPrimary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.canvas, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func paneTitle(_ title: String, _ hint: String) -> some View {
        HStack(spacing: 6) {
            Text(title).font(.system(size: 12, weight: .semibold))
            Text(hint).font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func pageArrows(count: Int) -> some View {
        HStack(spacing: 12) {
            Button { page = max(0, page - 1) } label: { Image(systemName: "chevron.left") }
                .disabled(page == 0)
            Text("Page \(page + 1) of \(count)").font(.system(size: 12).monospacedDigit())
            Button { page = min(count - 1, page + 1) } label: { Image(systemName: "chevron.right") }
                .disabled(page >= count - 1)
        }
        .buttonStyle(.gelSecondary)
        .frame(maxWidth: .infinity)
    }

    /// The page at full pane width (both panes share one scroll, so they stay aligned), with box overlays.
    private func pageImage(_ image: CGImage, size: CGSize, boxes: [Redactor.RenderedPage.Box], before: Bool) -> some View {
        Image(decorative: image, scale: 1)
            .resizable()
            .aspectRatio(size.width / max(size.height, 1), contentMode: .fit)
            .overlay {
                GeometryReader { geo in
                    ForEach(Array(boxes.enumerated()), id: \.offset) { _, box in
                        let key = box.value.lowercased()
                        let r = CGRect(x: box.rect.minX * geo.size.width, y: box.rect.minY * geo.size.height,
                                       width: box.rect.width * geo.size.width, height: box.rect.height * geo.size.height)
                            .insetBy(dx: -2, dy: -2)
                        overlay(kept: unticked.contains(key), before: before, pulsing: pulse == key)
                            .frame(width: r.width, height: r.height)
                            .position(x: r.midX, y: r.midY)
                            .id(before ? "box-\(key)" : "after-\(key)-\(r.minY)")
                            .help(box.value)
                    }
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .shadow(color: Theme.shadow, radius: 3, y: 1)
            .frame(maxWidth: .infinity)
    }

    @ViewBuilder private func overlay(kept: Bool, before: Bool, pulsing: Bool) -> some View {
        if before {
            if kept {
                RoundedRectangle(cornerRadius: 2)
                    .strokeBorder(Color.gray, style: StrokeStyle(lineWidth: 1.2, dash: [3, 2]))
                    .overlay(alignment: .topTrailing) {
                        Text("kept").font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 3)
                            .background(Color.gray, in: RoundedRectangle(cornerRadius: 2))
                            .offset(y: -9)
                    }
            } else {
                RoundedRectangle(cornerRadius: 2).fill(Color.red.opacity(0.28))
                    .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(Color.red.opacity(0.8), lineWidth: 1))
            }
        }
        if pulsing {
            RoundedRectangle(cornerRadius: 3).strokeBorder(Theme.accent, lineWidth: 3).padding(-3)
        }
    }

    // MARK: - Findings list

    private var findingsList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(groups, id: \.category) { group in
                    VStack(alignment: .leading, spacing: 2) {
                        groupHeader(group.category, group.items)
                        ForEach(group.items) { row($0) }
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .disabled(disabled || !allLoaded)
        .opacity(disabled ? 0.6 : 1)
    }

    private func groupHeader(_ category: String, _ items: [Item]) -> some View {
        let keys = Set(items.filter(locatable).map(\.key))
        let ticked = keys.subtracting(unticked).count
        return Toggle(isOn: Binding(
            get: { ticked > 0 },
            set: { on in if on { unticked.subtract(keys) } else { unticked.formUnion(keys) } })) {
            HStack(spacing: 6) {
                Text(category.uppercased()).font(.system(size: 11, weight: .semibold)).tracking(0.5)
                Text("\(ticked) of \(keys.count)").font(.system(size: 11).monospacedDigit()).foregroundStyle(Theme.textSecondary)
            }
        }
        .toggleStyle(.checkbox)
        .padding(.bottom, 2)
    }

    @ViewBuilder private func row(_ item: Item) -> some View {
        if allLoaded && !locatable(item) {
            HStack(spacing: 8) {
                Image(systemName: "minus").font(.system(size: 9)).foregroundStyle(Theme.textSecondary).frame(width: 14)
                Text(item.value).font(.system(size: 12, design: .monospaced)).lineLimit(1).foregroundStyle(Theme.textSecondary)
                Text(item.label).font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                Spacer()
                Text("Not on a page — nothing to black out").font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
            }
            .padding(.leading, 18).padding(.trailing, 6).frame(height: 24)
            .opacity(0.7)
        } else {
            tickRow(item)
        }
    }

    private func tickRow(_ item: Item) -> some View {
        let isOn = !unticked.contains(item.key)
        return HStack(spacing: 8) {
            Toggle("", isOn: Binding(get: { isOn }, set: { on in
                if on { unticked.remove(item.key) } else { unticked.insert(item.key) }
            }))
            .toggleStyle(.checkbox).labelsHidden()
            Button { jump(to: item) } label: {
                HStack(spacing: 8) {
                    Text(item.value).font(.system(size: 12, design: .monospaced)).lineLimit(1)
                        .strikethrough(!isOn, color: Theme.textSecondary)
                        .foregroundStyle(isOn ? Theme.textPrimary : Theme.textSecondary)
                    Text(item.label).font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Text(location(of: item)).font(.system(size: 11)).foregroundStyle(Theme.textSecondary).lineLimit(1)
                    if !isOn {
                        Text("kept").font(.system(size: 10, weight: .semibold)).foregroundStyle(Theme.textSecondary)
                            .padding(.horizontal, 5).background(Theme.hairline, in: Capsule())
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 18).padding(.trailing, 6).frame(height: 24)
        .background(pulse == item.key ? Theme.accentSoft : .clear, in: RoundedRectangle(cornerRadius: 5))
    }

    /// "Resume_REYES p.2" — the first file/page where the value has a box, or "not on a page".
    private func location(of item: Item) -> String {
        let fileName: (URL) -> String = { ($0.lastPathComponent as NSString).deletingPathExtension }
        for url in [current].compactMap({ $0 }) + item.files where item.files.contains(url) {
            if case .ready(let rendered, _) = previews[url],
               let p = rendered.first(where: { $0.boxes.contains { $0.value.lowercased() == item.key } }) {
                return files.count > 1 ? "\(fileName(url)) p.\(p.index + 1)" : "p.\(p.index + 1)"
            }
        }
        return files.count > 1 ? (item.files.first.map(fileName) ?? "") : ""
    }

    private func jump(to item: Item) {
        let target = (current.map { item.files.contains($0) } ?? false) ? current : item.files.first
        if target != current { selected = target }
        if let url = target, case .ready(let rendered, _) = previews[url],
           let p = rendered.first(where: { $0.boxes.contains { $0.value.lowercased() == item.key } }) {
            page = rendered.firstIndex { $0.index == p.index } ?? 0
        }
        pulse = item.key
        let key = item.key
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { if pulse == key { pulse = nil } }
    }

    // MARK: - Rendering

    private func loadPreview(for url: URL?) {
        guard let url, previews[url] == nil, let file = files.first(where: { $0.url == url }) else { return }
        previews[url] = .loading
        let keep = unticked
        Task.detached(priority: .userInitiated) {
            let state: Preview
            do {
                let rendered = try Redactor.renderPages(url, findings: file.findings, keep: [])
                if rendered.isEmpty, let kind = DocKind.from(url: url), kind == .docx || kind == .text {
                    state = .unavailable
                } else {
                    var after: [Int: CGImage] = [:]
                    for p in rendered { after[p.index] = Redactor.redactedImage(original: p.original, boxes: p.boxes, keep: keep) }
                    state = .ready(pages: rendered, after: after)
                }
            } catch {
                state = .failed(error.localizedDescription)
            }
            await MainActor.run { previews[url] = state; updateSummary() }
        }
    }

    /// Re-renders After for every loaded file when ticks change; debounced, newest wins.
    private func refreshAfter() {
        afterGeneration += 1
        let generation = afterGeneration
        let keep = unticked
        let loaded: [(URL, [Redactor.RenderedPage])] = previews.compactMap { url, state in
            if case .ready(let rendered, _) = state { return (url, rendered) } else { return nil }
        }
        Task.detached(priority: .userInitiated) {
            try? await Task.sleep(nanoseconds: 60_000_000)
            var results: [URL: [Int: CGImage]] = [:]
            for (url, rendered) in loaded {
                var after: [Int: CGImage] = [:]
                for p in rendered { after[p.index] = Redactor.redactedImage(original: p.original, boxes: p.boxes, keep: keep) }
                results[url] = after
            }
            let rendered = results
            await MainActor.run {
                guard generation == afterGeneration else { return }
                for (url, after) in rendered {
                    if case .ready(let rendered, _) = previews[url] { previews[url] = .ready(pages: rendered, after: after) }
                }
            }
        }
    }
}
