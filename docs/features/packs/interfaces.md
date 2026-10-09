# F7 · Packs — Interfaces

## Exposed (`Gel/GelCore/PII/PIIDetector.swift`)

```swift
public struct PIIType: Codable, Hashable {
    public var id: String          // "SSS"; may repeat across entries for alternative patterns
    public var label: String       // "SSS number"
    public var category: String    // fixed list, see spec
    public var pattern: String     // NSRegularExpression syntax
    public var group: Int?         // capture group holding the value (default 0)
    public var validator: String?  // "luhn" or nil
}

public struct Pack: Codable, Hashable, Identifiable {
    public var id: String; public var name: String; public var description: String
    public var audience: String?   // "Work" | "Personal"
    public var alwaysOn: Bool?     // core pack
    public var types: [PIIType]
    public var sampleQuestions: [String]?
}

public final class PackStore {
    public static let shared: PackStore
    public private(set) var packs: [Pack]          // always-on first, then by name
    public init()                                  // calls reload()
    public func reload()                           // bundled pack_*.json, then $GEL_HOME/Packs/*.json (same id overrides)
    public var selectablePacks: [Pack]             // packs where alwaysOn != true
    public func types(active: [String]) -> [PIIType]   // always-on + active, de-duplicated by id+pattern
}
```

Settings (`Gel/GelCore/Support/Settings.swift`): `GelSettings.shared.activePacks: [String]` (default `["hr"]`).

## Consumed by

- `PIIDetector.patternFindings(_:packs:)` → `packStore.types(active:)` ([detection-redaction](../detection-redaction/interfaces.md)).
- UI: onboarding, Settings → Packs, menu bar Pack submenu read `selectablePacks` and write `activePacks`; policy `requiredPacks` ([policy-dpo-report](../policy-dpo-report/interfaces.md)) is applied by the UI (forced on, disabled).

## Invariants

- A pack is configuration only; adding one needs no code change.
- The core pack (`alwaysOn: true`) is always active and never shown as a toggle.
- Malformed JSON is skipped silently by `reload()`.
