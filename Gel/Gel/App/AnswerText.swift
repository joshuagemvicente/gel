import SwiftUI
import GelCore

/// Answer text with `[n]` markers drawn as clickable number pills (launcher and History share it).
/// While streaming, `citations` is nil: every marker shows as a pill but none is clickable yet.
/// Once the answer is final, markers with no matching citation are dropped.
struct AnswerText: View {
    var text: String
    var citations: [Citation]?
    var onOpen: (Citation) -> Void = { _ in }

    var body: some View {
        Text(Self.attributed(text, valid: citations.map { Set($0.map(\.id)) }))
            .environment(\.openURL, OpenURLAction { url in
                guard url.scheme == "gel-cite", let n = Int(url.host ?? ""),
                      let c = citations?.first(where: { $0.id == n }) else { return .discarded }
                onOpen(c)
                return .handled
            })
    }

    // Private-use characters survive the markdown parse, so pills replace them after it.
    private static let open = "\u{E000}", close = "\u{E001}"

    static func attributed(_ s: String, valid: Set<Int>?) -> AttributedString {
        // Inline-only markdown keeps "- " list markers as text; show them as bullets.
        var text = s.split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.hasPrefix("- ") ? "•  " + $0.dropFirst(2) : String($0) }
            .joined(separator: "\n")
        var rebuilt = ""
        var cursor = text.startIndex
        for marker in QueryEngine.citationMarkers(in: text) {
            var before = String(text[cursor..<marker.range.lowerBound])
            let numbers = marker.numbers.filter { valid?.contains($0) ?? true }
            // A dropped marker takes its leading space with it ("Reyes [8]." → "Reyes.").
            if numbers.isEmpty, before.hasSuffix(" ") { before.removeLast() }
            rebuilt += before + numbers.map { open + String($0) + close }.joined()
            cursor = marker.range.upperBound
        }
        text = rebuilt + text[cursor...]
        var out = (try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
            ?? AttributedString(text)
        while let start = out.range(of: open), let end = out[start.upperBound...].range(of: close) {
            let n = Int(String(out.characters[start.upperBound..<end.lowerBound])) ?? 0
            var pill = AttributedString("\u{2009}\(n)\u{2009}")
            pill.font = .system(size: 10, weight: .semibold).monospacedDigit()
            pill.foregroundColor = Theme.accent
            pill.backgroundColor = Theme.accentSoft
            pill.baselineOffset = 2
            if valid != nil { pill.link = URL(string: "gel-cite://\(n)") }
            // A thin gap between adjacent pills ("1 2 3"), outside the tinted run.
            let next = end.upperBound < out.endIndex && out.characters[end.upperBound] == Character(open)
            if next { pill.append(AttributedString("\u{2009}")) }
            out.replaceSubrange(start.lowerBound..<end.upperBound, with: pill)
        }
        return out
    }
}
