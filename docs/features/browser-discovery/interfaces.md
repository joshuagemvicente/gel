# F5a · Automatic browser discovery — Interfaces

**Status:** proposed interfaces, not existing APIs. Use [spec.md](spec.md) for behaviour. Keep Swift 5, macOS 15 and the existing XCTest/ObservableObject conventions; this brief does not authorize a toolchain or test-framework migration.

## 1. Module boundaries

| Location | Responsibility | Dependencies |
| --- | --- | --- |
| `Gel/GelCore/Policy/` | Evidence values, identity normalization and effective-coverage resolution | Foundation; no SwiftUI, AppKit workspace or clipboard calls |
| `Gel/GelCore/PII/` | Pure clipboard-version/warning/accounting decisions; existing detection/redaction | Foundation and existing engine types |
| `Gel/GelCore/Support/Settings.swift` | The two ID-array preferences | Existing injected UserDefaults |
| `Gel/Gel/LeakGuard/` | Native discovery, pasteboard/frontmost adapters, workers and monitor orchestration | AppKit, GelCore, existing overlay |
| `Gel/Gel/App/AppState.swift` | Published coverage/status and configuration-change signals | Existing main-actor ObservableObject pattern |
| `Gel/Gel/Settings/` | Coverage controls and rendering from published values | SwiftUI/AppKit; no discovery in `body` |
| `Gel/GelCoreTests/` | Pure decisions and isolated preference/storage tests | XCTest and GelCore |

These are placement boundaries, not a requirement to create one file or protocol for each row. Use value types for evidence/results and final classes where services own workers, observations or panels. Expose only what the app/test target needs.

## 2. GelCore evidence and coverage values

Proposed names below give the implementation a common vocabulary. Concrete initializers must enforce normalization where stated.

| Type | Required information |
| --- | --- |
| `AppProtectionSource` | Closed cases: registered web handler, running-bundle web declaration, known browser, known chat app, manual addition, explicit policy |
| `WebLinkEvidence` | Exact bundle ID; optional display label; registered/declared schemes; valid-application/background-only/self-app facts supplied by the native adapter |
| `ProtectedAppDescriptor` | Exact bundle ID as stable identity; display label; evidence-source set; availability (`installed`, `notFound`, `unknown`) |
| `AppProtectionOverrides` | Normalized `manualBundleIDs` and `excludedBundleIDs`; no names, paths or clipboard state |
| `AppCoverageInput` | Candidate descriptors/evidence, known labels, overrides and optional policy app list; preserve nil versus empty policy |
| `AppCoverageSnapshot` | Effective ID-to-label lookup, display rows/reasons and whether an explicit app policy applies |
| `CoverageEdit` | Add manual ID, exclude ID, remove exclusion or remove manual entry |
| `CoverageEditResult` | Updated overrides or a non-content result such as duplicate, invalid ID or policy-managed |

`AppProtectionResolver` provides synchronous pure operations equivalent to:

- `normalizeIDs(_:) -> [String]`: trim, remove empties, deduplicate and sort; preserve case.
- `resolve(_ input: AppCoverageInput) -> AppCoverageSnapshot`: implement C1 from the spec, without filesystem or shared-state reads.
- `applying(_ edit: CoverageEdit, to: AppProtectionOverrides, policyWatchedApps: [String]?) -> CoverageEditResult`: implement C2 and reject managed mutations.
- `qualifies(_ evidence: WebLinkEvidence) -> Bool`: implement BD1/BD2. Treat HTTP/HTTPS as scheme evidence, not a browser-brand check.

Keep the runtime membership lookup separate from display-only catalog presence. A known/manual/policy ID can remain effective while metadata says the app is not found. A excluded or policy-unlisted installed app can appear in the UI without being effective.

### Existing preference extension

Add `GelSettings.manualWatchedAppIDs: [String]` and `GelSettings.excludedWatchedAppIDs: [String]`, backed by the identically named keys. Getters return `[]` for missing keys; setters persist normalized ID arrays.

Tests construct `GelSettings(defaults: isolatedDefaults, env: [:])`. Do not add global state to make these preferences testable and do not modify concurrent, unrelated settings additions.

## 3. GelCore clipboard decision state

### Values

| Value | Fields / role |
| --- | --- |
| `ClipboardRevision` | In-memory process-session UUID and observed change count |
| `ClipboardScanToken` | Revision, monitor lifecycle generation and pack-configuration version |
| `ClipboardTriggerSnapshot` | Revision/token, destination ID/name, summary, immutable category counts and current warn/block action; original findings/text remain memory-only if needed for redaction |
| `IncidentDisposition` | Whether a validated trigger needs an overlay and whether it is the first count group for this revision; blocking can still be required without a new warning |
| `ClipboardWriteOrigin` | Exact observed revision for a confirmed Gel write, without a persisted text hash |
| `ClipboardWriteReceipt` | Validated source revision and confirmed resulting own-write revision; lets block accounting commit before retiring the original ledger |

A `ClipboardIncidentLedger` owns only the current revision's warned IDs and first-incident accounting marker. It does not store clipboard strings, findings, a revision history or disk data.

Operations must support these distinct stages:

1. **Reconcile revision:** replace the ledger's current revision when an external change occurs, dropping prior warning/accounting markers.
2. **Plan:** ask whether a particular app needs a warning/accounting group without consuming either marker.
3. **Commit:** consume the warning key and optional first-count marker only after the orchestrator validates current state and completes any required block write.
4. **Handle own write:** retire the original sensitive revision; exact own writes do not generate a new sensitive incident.
5. **Pause/stop:** preserve non-content markers for an unchanged revision while releasing the controller's text/results and invalidating work.

Planning must be side-effect-free: a cancelled scan, stale action or failed write cannot prematurely consume another browser's warning or first incident. Commit must reject a revision that no longer matches the ledger.

Use one engine decision path in production and tests. Do not write a test-only duplicate of the monitor's eligibility logic. Keep OS effects in the app adapter; make version/ledger decisions callable from GelCoreTests.

Keep explicit safe-paste request tokens separate from automatic scan tokens. Monitoring pause invalidates automatic work, but must not accidentally disable an explicit user-requested paste-redaction action. Both paths still validate lifecycle, source revision and destination before effects.

### Grouped event writer

A proposed `Store.logLeakIncident(app: String, counts: [String: Int])` writes the existing first-trigger event group while holding Store's existing recursive lock across the calls. Emit `leak_caught` once and sorted category-count `leak_item` rows afterward; unrelated writers cannot split the group. No new event kind, table, content payload or crash-recovery guarantee is required. An isolated Store and concurrent event-sink test must exercise this real grouped path.

## 4. Native discovery service

An app-owned `@MainActor final class BrowserDiscoveryService: ObservableObject` exposes a read-only published discovery snapshot/status. AppState can forward or incorporate these values for Settings.

Required operations:

| Operation | Contract |
| --- | --- |
| `start()` | Idempotently install lifecycle observation and request initial discovery. Publish fallback coverage before waiting for discovery. |
| `stop()` | Cancel scheduled work, invalidate completion tokens and remove retained observer tokens. Repeated stop is safe. |
| `refresh(reason:)` | Coalesce requests according to BD4. Manual requests bypass the miss cooldown, not lifecycle validation. |
| `inspectActivatedApp(_:)` | Inspect supplied identity/bundle evidence for an unknown frontmost app without launching it. Reuse the same qualification path as a full refresh. |

The discovery result contains candidate descriptors plus non-content status/reason codes. A successful empty result differs from a thrown adapter failure. A partial result identifies incompleteness without exposing paths. The service retains last usable in-memory data for the failure policy in BD5.

### Native adapter calls

- `NSWorkspace.shared.urlsForApplications(toOpen: URL)` for fixed HTTP/HTTPS probes.
- `NSWorkspace.shared.runningApplications` for current running-bundle evidence.
- Running-app `bundleIdentifier`, `bundleURL` and `localizedName` for identity/display.
- Bundle information for `CFBundleIdentifier`, display/name, `CFBundleURLTypes`, `CFBundleURLSchemes` and background-only eligibility.
- `urlsForApplications(withBundleIdentifier:)` or the existing bundle-ID lookup for metadata representative/availability where needed.
- Workspace notification-center observers for application launch/activation and wake. Retain their tokens.

The adapter never calls `open`, modifies a default handler, launches an app to identify it, or reads browser databases. Reject malformed URLs with ordinary optional/error handling rather than force unwraps.

### Refresh coordination

Maintain main-actor coordinator state: lifecycle generation, active request ID, pending reason set, last usable result and unknown-app miss deadlines. A fake monotonic clock and controllable provider must exercise debounce/cooldown behaviour.

Perform expensive metadata work on an explicit serial worker. Keep required AppKit access in the native adapter on the SDK-appropriate thread; deliver plain immutable evidence to the worker/resolver. Do not assume that marking a synchronous method `async` moves it off the main actor.

At completion, check generation/request validity and resolve membership against current policy/overrides. Schedule latest-frontmost/clipboard evaluation after publication. Native discoveries never call redaction or log caught incidents themselves.

## 5. Clipboard and effect adapters

Inject small adapters or closures at the monitor boundary. Production and the app-target verification harness must call the same orchestration methods.

| Boundary | Required contract and fake capability |
| --- | --- |
| Pasteboard access | Stable text read, revision inspection and replacement with expected-source revision. Fakes can change the revision during reads/writes and fail writes. |
| Frontmost app | Current bundle ID/name and application-instance identity where available. Fakes can switch destinations while work is suspended. |
| Fast detector | Scan exact input under captured packs; return findings with the original UTF-16 offsets. A deferred fake controls result order. |
| Redactor | Redact exact text/findings; return a result without writing the clipboard. A deferred fake tests stale completions. |
| Event sink | Receive a validated immutable count group; record `leak_caught` followed by its category counts using the existing Store. A spy asserts calls and adjacency. |
| Overlay sink | Show/update/hide immutable alert data without activation. A spy asserts destination and lifetime. |
| Paste synthesizer | Existing permission check and ⌘V mechanism; a fake records whether synthesis occurred. |
| Scheduler/clock | Poll, debounce, cooldown and overlay-dismiss timing; deterministic fakes avoid sleep-based tests. |

The expected-revision replacement operation is a preflight safety check, not atomic compare-and-swap. A production adapter must expose changed/failed outcomes and confirm its own resulting write before creating an origin marker. Fakes should also exercise the unpreventable external-write window so tests do not imply a stronger guarantee than NSPasteboard provides.

Keep pasteboard access and visible UI state on the main actor. A detection/redaction worker receives value snapshots, not a mutable AppState reference. Use a worker-owned detector instance where appropriate; coordinate pack-store reads/reloads instead of sharing unsynchronized mutable metadata. Cancellation invalidates results even when a synchronous detector cannot stop mid-call.

## 6. AppState and lifecycle wiring

- AppDelegate continues to own monitoring for the process lifetime. Wire discovery and monitor start after policy/preferences are available, independent of folder indexing and onboarding.
- Retain timers, observer tokens and owned tasks. Add idempotent monitor startup/stop and stop services during termination, preserving other termination work already present.
- AppState publishes the effective catalog/status and applies user edits through the pure resolver. It owns the current configuration version rather than mirroring coverage in unrelated views.
- Pack changes invalidate scan configuration and reconcile current clipboard. Membership/action changes recheck current app/action without resetting the incident ledger.
- Menu-bar pause uses an explicit monitor transition or observation path that invalidates scans, hides the panel and handles resume immediately. A bare boolean change alone is insufficient.
- Settings requests policy reload and catalog refresh on appearance through these services. Views do not read/write policy files, enumerate apps or run detection in their `body`.
- Keep service results out of the existing voice/model/launcher task ownership. Browser work must not cancel unrelated streams or replace concurrent voice changes.

## 7. Test seams and project generation

The current GelCoreTests target cannot import app-only services. Put normalization, qualification, refresh-decision values, ledger and token-validation decisions behind genuine GelCore seams. Test native effect orchestration with a DEBUG-only app-target harness using fake adapters; verify actual OS integration through the manual matrix.

The harness must construct an isolated monitor/service, not reuse `AppState.shared`, the real clipboard or production event sink. Inputs are named synthetic scenarios, not text supplied through public distributed notifications. It reports pass/fail, counts and reason codes without retaining clipboard data. Exclude it from Release behaviour.

Add new source files under existing source roots and regenerate with XcodeGen when implementation begins. Keep generated `Gel.xcodeproj` out of source edits. Do not invent a `GelTests` scheme or imply that current `gelcli` can exercise NSWorkspace discovery.
