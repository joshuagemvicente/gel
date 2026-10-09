# F5a · Automatic browser discovery — Verification

**Status:** verification plan only. No test in this file has run for the proposed feature. Test-case labels below describe required cases, not existing test methods or CLI commands.

The acceptance source is [spec.md](spec.md). Put pure XCTest cases in the existing GelCoreTests target; exercise actual app orchestration through the isolated DEBUG harness described in [interfaces.md](interfaces.md). Manual checks establish native integration and UI behaviour.

## 1. Isolation and fixtures

- Use only synthetic clipboard content. The primary small fixture is `TIN: 123-456-789`, with the HR pack enabled. Expected pattern finding: one government-ID item, redacted as a TIN placeholder.
- Use existing synthetic `demo-data/clipboard-samples/employee_record.txt` for multi-category checks and `clean_paragraph.txt` for clean-text checks. Verify actual detector output rather than hardcoding stale sample counts.
- A second revision can use `TIN: 987-654-321` or a clean string to expose stale-cache overwrites. A mixed placeholder fixture includes `[TIN_1]` plus a new raw hyphenated TIN; the raw item still requires detection.
- Use invented fixture IDs such as `org.example.gel.fixture.webapp`, `.router` and `.beta`. These are fixtures, not actual Dia/browser bundle IDs.
- For preference tests, inject a unique `UserDefaults(suiteName:)`, `env: [:]`, and remove only that test suite at teardown. Never erase the real Gel suite.
- For event tests, create a new temporary Store. `GEL_HOME` isolates application files/policy/database/reports, but not UserDefaults, Keychain, real clipboard or Accessibility grants.
- Run native/manual mutation checks in a test macOS account or a controlled test build with injected preferences. Save/restore only settings the tester changed. Do not remove a real company policy to make a test pass.
- Prefer the approved OpenCode temporary directory for agent-created fixture bundles/stores. Do not delete or overwrite a user's installed apps.
- Do not send any synthetic sample into a chat service. Paste into an empty input, inspect it and clear it.

## 2. Pure qualification and membership matrix

| Case | Input / action | Required result | Criteria |
| --- | --- | --- | --- |
| R01 | Registered HTTP-only app, not default | Qualifies and is protected without a brand entry | AC01 |
| R02 | Registered HTTPS-only app | Qualifies; both schemes are not required | AC01 |
| R03 | Running bundle declares a web scheme; registration query omits it | Qualifies from runtime evidence | AC02 |
| R04 | Link router has web-handler evidence | Included as a web-link app; no browser-identity promise | AC01, AC03 |
| R05 | HTML-only document editor or custom-scheme-only app | Does not qualify through automatic web evidence | AC04 |
| R06 | Missing ID, empty ID, nonexistent URL, non-app or background-only helper | Skip candidate; other valid apps survive | AC04 |
| R07 | Same ID from both schemes, multiple installations and manual/default sources | One row/key, combined sources; deterministic label | AC03 |
| R08 | Different channel IDs with identical names | Separate membership and warning identities | AC03, AC12 |
| R09 | No policy / nil policy list | Union handler/known/manual IDs minus exclusions | AC06 |
| R10 | Explicit empty policy list, discovered/manual browsers present | Empty effective set; managed controls | AC06 |
| R11 | Explicit nonempty policy list | Exactly listed IDs; ignored user exclusions/additions outside it | AC06 |
| R12 | Policy repeats IDs and includes surrounding whitespace/empty entries | No trap; normalized exact-ID set | AC06 |
| R13 | Unknown/uninstalled policy or manual ID | Membership retained; availability not claimed installed | AC06, AC21 |
| R14 | Known chat app and excluded known browser under nil policy | Chat remains protected; exclusion removes browser | AC03, AC22 |

Also assert automatic self-app exclusion, case-sensitive bundle matching and missing-name fallback without guessing IDs.

## 3. Preferences and editing matrix

| Case | Input / action | Required result | Criteria |
| --- | --- | --- | --- |
| S01 | Fresh isolated preferences | Empty overrides; automatic sources still protected | AC07 |
| S02 | Write duplicates/whitespace and read through a new GelSettings instance | Normalized ID arrays survive; no names/paths/catalog stored | AC07, AC23 |
| S03 | Add app currently excluded | Manual ID retained, exclusion removed, one row | AC07, AC20 |
| S04 | Exclude then reenable known/discovered/manual app | Exclusion wins, then original sources resume without duplication | AC20 |
| S05 | Remove manual entry for discovered/default app | Other source still protects it; exclusion unchanged | AC20 |
| S06 | Remove sole manual source | Membership disappears unless an explicit policy includes it | AC20 |
| S07 | Explicit policy appears while picker/confirmation is open | Edit rejected; saved overrides unchanged | AC07, AC20 |
| S08 | Policy removed, or organization policy has nil app list | Saved overrides become editable/effective; no forced reset | AC06, AC07 |

## 4. Discovery/refresh matrix

Use controllable provider completions and a monotonic fake clock. Do not assert race handling through arbitrary sleeps.

| Case | Stimulus | Required result | Criteria |
| --- | --- | --- | --- |
| D01 | Both URL queries return overlapping fixture bundles | Both sources queried; one descriptor per ID; no open call | AC01, AC03 |
| D02 | App launches from a nonstandard local location | Bundle evidence inspected without directory crawling | AC02, AC04 |
| D03 | One candidate has unreadable metadata | Remaining catalog publishes; status notes incompleteness | AC04, AC05 |
| D04 | Ordinary successful empty result | Empty discovered set, known/manual/policy fallback remains, honest help | AC05 |
| D05 | Adapter failure with/without a previous usable catalog | Keep last usable catalog when present, otherwise fallback only | AC05 |
| D06 | Burst of launch events within debounce window | One coalesced request, not one per launch event | AC08 |
| D07 | Repeated unknown-ID activation within 30 s | One inspection/miss refresh; manual Refresh bypasses cooldown | AC08 |
| D08 | Manual refresh during in-flight work | At most one pending full request; no parallel full scans | AC08, AC09 |
| D09 | Older/stopped-generation completion arrives | No stale publication, no overlay/event effect | AC09, AC25 |
| D10 | Policy/overrides change before provider completes | Resolve completion using latest configuration | AC09 |
| D11 | Current unlisted app qualifies on completion while clipboard is unchanged | Reevaluate latest app/clipboard without recopy | AC02, AC21 |
| D12 | Clipboard poll runs repeatedly with unchanged/changed text | Zero full-discovery calls from polling itself | AC08, AC24 |
| D13 | Successful refresh drops a removed app; then same ID returns | Automatic evidence changes; saved manual/exclusion IDs survive | AC21 |
| D14 | Repeated start, repeated stop, wake, then restart service | One observer/timer set; teardown blocks callbacks; restart uses current evidence | AC08, AC25 |

## 5. Ledger and token matrix

| Case | Stimulus | Required result | Criteria |
| --- | --- | --- | --- |
| L01 | Plan then cancel a first trigger | No warning/count marker consumed | AC13, AC15 |
| L02 | One revision triggers app A then app B | Two warning commits, one accounting commit attributed to A | AC11, AC13 |
| L03 | Return to A; dismiss/timeout; refresh catalog | No extra warning/count for A | AC11 |
| L04 | Copy identical content with a new count | Fresh warnings and a new accounting group allowed | AC12 |
| L05 | Two windows/profiles use one bundle ID | One warning key | AC12 |
| L06 | Beta and stable channels share display name, not ID | Separate warning keys, one revision count group | AC03, AC12 |
| L07 | Revision changes before commit | Reject old commit; new revision unaffected | AC15 |
| L08 | Pause/resume with unchanged revision | Keep consumed markers; fresh scan allowed | AC18 |
| L09 | Copy while paused, then resume | New revision eligible for warnings/counting | AC10, AC18 |
| L10 | Own block/safe-paste write, then switch apps | Retired sensitive revision cannot warn/count again | AC16 |
| L11 | New process session observes same pasteboard count | New ledger can warn/count, with no persisted history | AC13, AC23 |
| L12 | Pack/coverage/action changes, revision unchanged | No incident reset; newly eligible app can warn; existing blocking action still evaluated | AC13, AC15 |
| L13 | Old pack version/lifecycle token finishes | Result rejected before effects | AC15, AC25 |
| L14 | No protected destination, clean/empty/non-string data | No caught incident, even if detection previously ran | AC17 |

## 6. App orchestration and controlled-race matrix

Construct the production orchestrator with fake adapters. Run through real controller entry points for poll, activation, resume, configuration change, safe paste and shutdown. The harness may inspect synthetic in-memory snapshots to assert results but must not log or persist their text.

| Case | Controlled scenario | Required result | Criteria |
| --- | --- | --- | --- |
| C01 | Startup finds sensitive clipboard with protected frontmost app | Scan and trigger without a new copy | AC10 |
| C02 | Count changes between string-read boundaries | Discard unstable snapshot; no old-text event/overlay/write | AC15 |
| C03 | Old scan completes after newer clean/sensitive text | Old result cannot overwrite latest state | AC15, AC17 |
| C04 | Destination changes while detector runs | Evaluate actual current destination; no stale app label/focus action | AC15, AC26 |
| C05 | Pause/stop/configuration invalidates in-flight scan | No stale side effects; resume scans current input | AC18, AC25 |
| C06 | Block snapshot writes redacted text then clears live findings | Preserved nonempty summary and original category-count group | AC13, AC14 |
| C07 | New clipboard arrives while old redaction is pending | Do not overwrite it or synthesize paste from old text | AC15 |
| C08 | Pasteboard replacement fails | No “blocked” success, no synthesized paste, bounded retry guidance | AC14, AC15 |
| C09 | App loses coverage, or clipboard becomes non-string | Hide stale overlay; leave unrelated clipboard representations untouched | AC17 |
| C10 | Sensitive text copied while paused | No automatic content read/action during pause; current text scanned on resume | AC18 |
| C11 | External mixed placeholder/raw fixture versus confirmed Gel write | External raw finding detected; exact own write does not loop | AC16 |
| C12 | Accessibility absent; explicit safe paste also invoked while paused | Redacted clipboard plus existing manual ⌘V guidance; no new discovery prompt or automatic incident merely from the explicit action | AC18, AC22, AC23 |
| C13 | App/action changes after warning; existing revision now requires block | Current action enforced without new incident or old destination effects | AC13–AC15 |

Use an event spy to prove one ordered count group. Repeat C06 with an isolated Store and compare `DPOReport.totals`: one incident and the fixture's actual category counts. Exercise the real grouped writer with unrelated concurrent event writes and prove it does not interleave rows inside a group. Existing Store insertion failures are not an exactly-once guarantee; record that boundary rather than silently retrying count groups.

## 7. Native/manual walkthrough

Run with warmed detection, HR enabled and no explicit policy for warning-repeat tests. Use a separate block-policy pass. Record installed browser versions; unavailable browsers stay pending.

| Case | Steps | Pass condition | Criteria |
| --- | --- | --- | --- |
| M01 · Known browsers | Copy small TIN fixture; activate Chrome, Safari, Brave and Firefox where installed | Each protected app can warn for that revision; labels name the current app. Return to the first app: no repeat. | AC11, AC12, AC22 |
| M02 · Non-static browser | Launch installed Dia or another non-static handler while Gel runs; inspect Settings; activate it with sensitive clipboard | Coverage appears without an ID-list edit/restart, then warning appears without recopy. If no such browser is available, use a local synthetic handler bundle for adapter evidence and leave real-browser UI verification pending. | AC02, AC21 |
| M03 · Generic website scope | In a protected browser, use ChatGPT/Claude input and a local/non-AI page | Same app-level protection; no tab/site permission request. Do not submit text. | AC11, AC23 |
| M04 · Add fallback app | Choose a local fixture app with no web declaration; cancel once, then add | Cancel changes nothing; valid add stores its ID and protects activation; no app launch from the picker itself. | AC07, AC20 |
| M05 · Exclusion | Exclude a browser; copy fresh TIN and activate it; reenable and reconcile | Excluded app does not warn; other apps remain covered. Reenabled current app can evaluate unchanged text if not already warned for that revision. | AC07, AC20 |
| M06 · Managed lists | Test explicit one-ID, empty and nil app lists in isolated policy files | Exact listed coverage, no coverage for empty list, editable automatic coverage for nil list. User overrides restore after policy removal. | AC06, AC19 |
| M07 · Sheet authority race | Open Add app/exclusion sheet, install explicit test policy, then confirm | Saved edit does not apply; clear managed explanation. | AC20 |
| M08 · Startup and pause | Copy TIN before launch; launch with protected app active. Pause, copy a second fixture, resume | Initial and resumed text evaluated. No automatic clipboard-content checks/action while paused; deliberate safe paste still works without resuming monitoring. | AC10, AC18 |
| M09 · Block and safe paste | Install isolated sample block policy; copy fixture; activate browser; paste with ⌘V, then test fresh fixture with safe paste | Input contains placeholders, overlay retains original summary/counts, one incident group. Accessibility fallback works without claiming synthesis. | AC13, AC14, AC22 |
| M10 · Stale alert | Show warning, copy clean/second text and invoke safe paste before next ordinary poll | New text survives or is redacted from its own current findings; old TIN is not pasted/restored. Use harness for deterministic race coverage. | AC15 |
| M11 · UI accessibility | Navigate card/controls/sheets by keyboard and VoiceOver; use long names and Reduce Motion | States/reasons accessible, controls fit, Escape cancels, background refresh doesn't take focus. | AC19, AC26 |
| M12 · Offline independence | Turn Wi-Fi off, stop Ollama, use no indexed folder; refresh and copy fixture | Discovery and warning/redaction still work locally with no new permission prompt. | AC23 |
| M13 · Wake and lifetime | Close main window; activate browser; sleep/wake; quit during pending refresh | Monitoring stays active after window close, reconciles after wake, rejects completion after quit. | AC08, AC25 |
| M14 · Audit and timing | Warn in two apps, inspect Home/report, restart with same clipboard; measure refresh/warning times | One count group before restart, first-app attribution, possible new group after restart disclosed; record actual timing against targets. | AC13, AC23, AC24 |

A local fixture handler must live in a scratch directory, declare only synthetic metadata and make no network requests. Do not change the default browser or register a handler through destructive/private system tools. Actual browser validation requires its real bundle evidence; synthetic qualification cannot establish that a particular untested browser works.

## 8. Build and CLI checks after implementation

Run from `Gel/`, following [project conventions](../../project/conventions.md):

```sh
xcodegen generate
xcodebuild -project Gel.xcodeproj -scheme gelcli -derivedDataPath build -quiet build
xcodebuild -project Gel.xcodeproj -scheme Gel -derivedDataPath build -quiet build
xcodebuild -project Gel.xcodeproj -scheme Gel -derivedDataPath build test -only-testing:GelCoreTests
```

For synthetic detector sanity, set `GEL_HOME` to a new scratch directory before CLI use:

```sh
CLI=build/Build/Products/Debug/gelcli
"$CLI" detect --packs hr "TIN: 123-456-789"
"$CLI" detect --packs hr --file "../demo-data/clipboard-samples/employee_record.txt"
"$CLI" detect --packs hr --file "../demo-data/clipboard-samples/clean_paragraph.txt"
"$CLI" stats
```

These commands verify the detector/store, not native browser discovery or monitor races. The DEBUG scenario harness must produce its own pass/fail summary through the implementation's approved invocation; no such command exists yet.

## 9. Evidence and completion

Record each run with: build revision, macOS/browser version, synthetic scenario ID, result, observed counts and durations, plus any reason for pending coverage. Capture no real clipboard text, personal browser profile, account sidebar or full app inventory in screenshots/reports.

- Mark a task complete only after its required pure, harness and native checks pass.
- Attach evidence to every AC01–AC26 or leave it pending. An unavailable browser is not a pass.
- Check database events, exported reports and preference keys for fixture values, filenames, paths, hashes and revision/history keys. This feature may persist only agreed ID arrays and counts/category/app-label events.
- Review code paths for network/browser-content access; offline UI alone cannot prove an absence of attempted requests.
- Remove temporary verification instrumentation or keep it explicitly DEBUG-only. Do not commit generated fixture apps, build products, real metadata or generated Xcode project files.
- Report any failed timing target or existing test regression without widening this feature to unrelated fixes.

For this documentation-only delivery, validate local Markdown links, referenced existing paths, cross-file IDs and whitespace. An app build is not required, and none of the runtime criteria should be marked passed.
