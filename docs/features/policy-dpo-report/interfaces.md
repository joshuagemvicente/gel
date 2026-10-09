# F8 · Team policy and DPO report — Interfaces

## Exposed (`Gel/GelCore/Policy/TeamPolicy.swift`)

```swift
public struct TeamPolicy: Codable, Equatable {
    public var organization: String
    public var requiredPacks: [String]?
    public var watchedApps: [String]?              // bundle IDs; nil = LeakGuardDefaults
    public var actions: [String: String]?          // type id or category → "warn" | "block"
    public var allowCloudFallback: Bool?
    public static func load(from url: URL = GelPaths.policy) -> TeamPolicy?
    public func action(for finding: Finding) -> String   // type id, then category, default "warn"
    public func blocks(_ findings: [Finding]) -> Bool
    public static let sample: TeamPolicy           // Bayanihan Outsourcing Corp.
}

public enum LeakGuardDefaults {
    public static let watchedApps: [String: String]   // bundle id → display name
}

public enum DPOReport {
    public static func csv(since: Date, store: Store = .shared) -> String
    public struct Totals {
        public var leaksCaught: Int; public var itemsProtected: Int; public var redactions: Int
        public var localAnswers: Int; public var cloudAnswers: Int; public var byCategory: [String: Int]
        public var localShare: Double   // 1 when no answers yet
    }
    public static func totals(since: Date = .distantPast, store: Store = .shared) -> Totals
    public static func export(since: Date, organization: String?) throws -> [URL]   // [csv, pdf] in GelPaths.reports
}
```

Paths (`Support/Settings.swift`): `GelPaths.policy` (`<home>/policy.json`), `GelPaths.reports` (`<home>/Reports/`, created on access).

## Consumed

- `Store.events(since:)` and its `Event` (`date, kind, category, count, app, provider`).
- `Finding` from [detection-redaction](../detection-redaction/interfaces.md).
- Sets `ModelRouter.shared.cloudAllowedByPolicy` ([model-fallback](../model-fallback/interfaces.md)) — done by the app at launch.

## Event contract (what writers must log; counts only)

| kind | category | count | app | provider | written by |
| --- | --- | --- | --- | --- | --- |
| `query` | — | 1 | — | `local`/`cloud` | `QueryEngine.ask` |
| `cloud_call` | `chat`/`detect` | payload chars | — | `cloud` | `ModelRouter` |
| `leak_caught` | — | 1 | app name | — | leak-guard (app) |
| `leak_item` | category | n | app name | — | leak-guard (app) |
| `redaction` | — | 1 | — | — | redact flow (app) |
| `redaction_item` | category | n | — | — | redact flow (app) |

## Invariants

- Reports never include document text, file names or clipboard text.
- No policy file → `load()` returns nil → everything unmanaged.

## Callers

[app-shell](../app-shell/spec.md) (load at launch), [settings](../settings/spec.md), [leak-guard](../leak-guard/interfaces.md), [home](../home/spec.md), [redactions-module](../redactions-module/spec.md), `gelcli stats`.
