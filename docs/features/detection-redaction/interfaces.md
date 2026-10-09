# F4 · Detection and redaction — Interfaces

## Exposed (`Gel/GelCore/PII/`)

```swift
public struct Finding: Hashable, Codable, Identifiable {
    public var type: String       // e.g. "SSS", "NAME", "ADDRESS"
    public var label: String      // "SSS number"
    public var category: String   // "government ID", "salary", "address", …
    public var text: String       // the matched value (in memory only)
    public var range: NSRange     // UTF-16 range in the scanned text
    public var layer: Int         // 1 pattern, 2 name tagger, 3 LLM
}

public final class PIIDetector {
    public static let shared: PIIDetector
    public var packStore: PackStore
    public func patternFindings(_ text: String, packs: [String]) -> [Finding]                 // layer 1
    public func nameFindings(_ text: String) -> [Finding]                                     // layer 2
    public func detectFast(_ text: String, packs: [String] = GelSettings.shared.activePacks) -> [Finding]      // 1+2, merged
    public struct FullResult { public var findings: [Finding]; public var llmProvider: ProviderKind? }
    public func detectFull(_ text: String, packs: [String] = GelSettings.shared.activePacks) async -> FullResult // 1+2+3
    public static func merge(_ findings: [Finding]) -> [Finding]
    public static func summary(_ findings: [Finding]) -> String     // "3 government ID numbers, 1 salary, 1 address"
}

public enum Redactor {
    public struct TextResult { public var text: String; public var mapping: [String: String]; public var counts: [String: Int] }
    public static func redactText(_ text: String, findings: [Finding]) -> TextResult
    public static func cloudSafe(_ text: String, packs: [String] = GelSettings.shared.activePacks) throws -> String
    public struct FileResult { public var output: URL; public var counts: [String: Int] }
    public static func outputURL(for source: URL, ext: String) -> URL          // <folder>/Redacted/<name>_REDACTED.<ext>
    public static func redactFile(_ url: URL, findings: [Finding], keep: Set<String> = []) throws -> FileResult
}
```

`PackStore`, `Pack`, `PIIType`: see [packs interfaces](../packs/interfaces.md).

## Consumed

- `TextExtraction.extract`, `TextExtraction.render`, `TextExtraction.loadImage`, `OCR.recognizeLines` ([indexing](../indexing/interfaces.md)).
- `ModelRouter.shared.completeJSON(_:redactForCloud:timeout:)` for layer 3, with `redactForCloud = Redactor.cloudSafe` ([model-fallback](../model-fallback/interfaces.md)).

## Invariants

- `cloudSafe` uses layers 1–2 only and never touches the network.
- `redactText` assigns tokens per `type + lowercased value` in reading order; `mapping` (token → value) is never persisted.
- `counts` are keyed by **category**.
- `redactFile` matches values case-insensitively on each page; `keep` holds lowercased values the user un-ticked.
- `redactFile` writes the output file only. **The caller** logs `Store.logEvent(kind: "redaction")`, one `Store.logEvent(kind: "redaction_item", category:, count:)` per category, and `Store.saveRedaction(source:output:counts:)`.

## Callers

`gelcli detect|redact`; [leak-guard](../leak-guard/interfaces.md) (`detectFast`, `summary`, `redactText`); [redactions-module](../redactions-module/spec.md) (`detectFull`, `redactFile`); [query-citations](../query-citations/interfaces.md) (`cloudSafe`).
