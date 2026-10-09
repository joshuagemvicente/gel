# F5a · Automatic browser discovery — Spec

**Status:** planned behaviour; no app implementation or acceptance checks have passed for this extension.

**Goal:** discover browser/web-link-app coverage on the Mac, explain and edit that coverage in Settings, and warn about recognized sensitive clipboard text once in each protected app without duplicating counts.

## 1. Terms and scope

| Term | Definition |
| --- | --- |
| Discovered web-link app | A qualifying app that macOS registers, or its running bundle declares, as an HTTP or HTTPS handler. It can be a browser or a link router. |
| Known app | An ID in `LeakGuardDefaults.watchedApps`, including existing browser, AI and chat-app entries. |
| Manual addition | A bundle ID the user adds by choosing a local `.app`. |
| Exclusion | A user-selected bundle ID omitted from automatic/default/manual coverage when no explicit company app list applies. |
| Effective coverage | The bundle-ID set the monitor uses after policy and user overrides. |
| Clipboard revision | The pasteboard's `changeCount` observed within the current running Gel session. Identical text copied again is a new revision. |
| Incident | A revision that first produces a valid sensitive-data trigger in a protected app. It does not prove that a paste or network transmission occurred. |
| Warning key | `(clipboard revision, protected app bundle ID)` within one Gel session. |
| Trigger snapshot | Immutable, in-memory data for a validated trigger, including summary, category counts, destination and action, captured before clipboard replacement. |

### Included

- Automatic local discovery, fallback coverage and refresh lifecycle.
- User additions/exclusions and a native Settings coverage section.
- Explicit company-list precedence, including empty lists.
- Existing-clipboard scans on start/resume, per-app warning deduplication and session-only incident accounting.
- Freshness validation and preserving trigger data through block/safe-paste clipboard writes.
- Pure decision tests, native-adapter harnesses and manual browser checks.

### Outside this feature

- Website-specific rules, tab inspection, browser history, profile access or webpage scraping.
- Extensions, AppleScript browser automation, Screen Recording permission or a new cloud service.
- Intercepting keyboard/paste events to prevent every raw paste, upload or typed disclosure.
- Discovering an embedded web view as a browser without handler evidence; users can add such an app manually.
- Persistent clipboard history, text hashes, cross-restart deduplication or a complete installed-app inventory.
- New detection patterns. In particular, the current HR TIN rule expects hyphenated values.
- New report schemas, destination-only audit events or global-hotkey registration changes.
- A Swift 6 concurrency/Observation migration or changes to indexed-folder behaviour.

## 2. Discovery contract

### BD1 · Sources

Build discovery candidates from these local sources:

1. Query `NSWorkspace.urlsForApplications(toOpen:)` for both `http://example.invalid/gel-browser-discovery` and `https://example.invalid/gel-browser-discovery`.
2. Inspect bundle metadata for the currently running apps, using URLs supplied by `NSWorkspace`, to cover launched apps whose registration has not appeared in the query results. A bundle declaration containing `http` or `https` in `CFBundleURLSchemes` qualifies as handler evidence.
3. Retain the existing known-app IDs as fallback membership. Resolve their local installation metadata when available for display; absence from the installed catalog does not erase the fallback ID.

Use the union of HTTP and HTTPS evidence. Neither being the default browser nor declaring both schemes is required. An HTML-document handler alone does not qualify.

Do not open the synthetic URLs, change default handlers, enumerate tabs or recursively crawl application directories. Scheme comparison is case-insensitive; bundle-ID matching is case-sensitive.

### BD2 · Candidate validation and identity

- Accept application bundles with a readable, nonempty bundle ID. Validate that the supplied URL refers to an application bundle rather than an `.appex`, `.xpc`, ordinary file or stale nonexistent path.
- Exclude Gel itself from automatic discovery and skip background-only helper bundles. Do not reject an app solely because it uses `LSUIElement`; menu-bar link-handling apps can qualify.
- A bundle's claim to handle a web scheme is sufficient evidence for this feature. Do not try to infer browser identity from its name, icon, vendor, Chromium/WebKit engine or category.
- Keep one catalog row and one warning identity per exact bundle ID. Multiple copies, windows, profiles and private windows share that identity. Separate beta/channel IDs remain separate apps.
- Deduplicate safely, including repeated IDs in policies. Avoid `Dictionary(uniqueKeysWithValues:)` on untrusted, undeduplicated inputs.
- Trim surrounding whitespace from configured IDs and drop empty entries. Preserve ID case and internal characters; do not invent IDs from app names.
- An app without usable identity cannot receive ID-based coverage. Skip it, keep the remaining candidates, and show non-content guidance if the user tries to add it manually.

### BD3 · Names and metadata

For an active trigger, prefer the validated running app's localized display name. For catalog rows, prefer the selected installed bundle's localized display name/name, then an existing known-app label, then the bundle ID.

Choose a duplicate-installation representative in this order: the frontmost/running copy, the first matching copy macOS ranks for that ID, then a stable local-URL ordering. Metadata choice changes presentation, not membership.

Keep app URLs/icons and discovered metadata in memory. Never put absolute app paths, icons or the discovery inventory in the events database, report, console logs or user preferences. Diagnostic messages may contain reason codes and aggregate counts, not paths or clipboard content.

### BD4 · Refresh lifecycle

| Event | Required action |
| --- | --- |
| Gel starts | Publish known/manual/policy coverage first; start discovery without waiting for onboarding or indexing. Inspect current clipboard separately. |
| An app launches | Inspect that running app and request a coalesced discovery refresh. |
| An unknown app becomes frontmost | Evaluate available evidence; request one targeted inspection and a rate-limited refresh. If it qualifies, reevaluate the latest clipboard in the app that is frontmost at completion. |
| Settings coverage appears | Request a refresh; show the previous catalog during work. Reload policy through the existing policy path before resolving coverage. |
| User chooses Refresh | Request a full refresh, bypassing the automatic cooldown but coalescing with an in-flight request. |
| Mac wakes | Refresh app evidence and reconcile the current clipboard when monitoring is active. |
| Policy/override changes | Recompute effective membership immediately from the current catalog, then reevaluate current clipboard/app state. Discovery need not finish first. |

Full discovery must not run in the 0.5 s clipboard poll or for every keystroke. Debounce bursts of launch notifications for 250 ms; allow at most one full automatic refresh in flight. For unknown-app activation, suppress repeated misses for the same ID for 30 s. Manual Refresh, app launch and wake can bypass that miss cooldown.

Allow one pending full-refresh request while work is in flight. Coalesce repeated requests into it. A lifecycle generation and request ID must prevent a stopped service or superseded result from publishing old data. Clear obsolete unknown-app miss entries when discovery succeeds or the app's launch metadata changes.

After publishing a catalog, resolve membership using the latest policy/preferences, not the configuration captured when discovery started. If the new catalog makes the current app eligible, reevaluate the current clipboard without requiring another copy or app switch.

### BD5 · Partial results and failure

- Skip an unreadable/malformed candidate and continue with other candidates. Describe incomplete discovery in Settings without including paths.
- An ordinary empty result is not proof of an API error: the API returns arrays, not a typed discovery error. Show that no web-link apps were found and offer Refresh/Add app; retain known/manual/policy membership.
- If the discovery adapter reports a real failure, retain the last usable in-memory discovered catalog and known/manual/policy coverage. With no previous result, use fallback membership only.
- A later successful full refresh replaces prior discovered membership. Apps removed from discovery and not supported by running metadata disappear from automatic coverage; manual/default/policy IDs retain their defined membership.
- The service can mark missing metadata as unavailable without deleting the user's additions or exclusions. Relaunch/refresh resolves the same ID again.
- Never silently turn off the entire monitor because discovery fails. Never describe an incomplete result as protection for every browser.

## 3. Effective coverage and company policy

### C1 · Precedence

Let `H` be discovered handler IDs, `K` known-app IDs, `M` manual IDs, `X` exclusions and `P` the optional company `watchedApps` list.

```text
P is present:  effective = deduplicated(P)
P is absent:   effective = (H union K union M) minus X
```

| Policy state | Meaning | User app controls |
| --- | --- | --- |
| No policy, or policy with `watchedApps == nil` | Automatic/default/manual coverage with exclusions | Editable |
| Policy with `watchedApps == []` | No watched apps, even if discovery finds browsers | Locked |
| Policy with a nonempty `watchedApps` list | Only those exact IDs; do not union in discovered/manual/default IDs | Locked |

A policy can manage other settings without managing app membership. An organization name alone does not lock coverage when `watchedApps` is nil.

Resolve labels for policy IDs from runtime/catalog/default metadata where available. Unknown or uninstalled policy IDs remain in membership and appear as ID-based rows; they can become effective on activation without changing the policy file.

Removing an explicit policy restores the user's saved manual additions/exclusions against the latest catalog. A policy does not delete or rewrite those preferences. Reloading/installing/removing a policy requests coverage resolution and current-state evaluation; the monitor uses the latest actions/required packs.

### C2 · User persistence and edits

Store only normalized arrays of bundle IDs in the existing GelSettings suite:

| Key / proposed property | Default | Meaning |
| --- | --- | --- |
| `manualWatchedAppIDs` | `[]` | User additions, sorted and deduplicated on write |
| `excludedWatchedAppIDs` | `[]` | User exclusions, sorted and deduplicated on write |

Existing installations need no migration prompt. Automatic discovery activates with empty overrides. Do not add an environment-variable override or persist a discovered catalog.

- **Add app…:** choose one local `.app`, read its bundle ID, add it to `M`, and remove that ID from `X`. The action does not launch the chosen app.
- Adding an app already protected creates no duplicate row. Show a short confirmation; a manual reason may coexist with discovery evidence.
- **Protect toggle off:** add the ID to `X`; preserve any manual addition so re-enabling restores its reason.
- **Protect toggle on:** remove the ID from `X`. An ID lacking automatic/default/manual evidence needs a manual addition to become protected.
- **Remove manual entry:** remove the ID from `M` only. Discovery/default evidence can still protect it. Explain this outcome before applying the action. Preserve an existing exclusion.
- Keep excluded IDs visible in an exclusions area even if the app is no longer discovered. Let the user remove an exclusion without locating the app again.
- Reject a picker item with no valid application identity. Do not persist its name/path as a substitute. Cancelling the picker or a confirmation changes nothing.
- Disable mutations under an explicit app policy. Recheck policy authority when a picker/confirmation returns, since the policy can change while a sheet is open.

## 4. Clipboard and warning state

### CL1 · Startup, freshness and scans

- On monitor start, inspect the existing clipboard instead of waiting for its count to change. On resume, reconcile and inspect the current clipboard before any action. A clipboard copied before Gel launched qualifies.
- On poll, activation, membership/configuration change and wake, first reconcile the current pasteboard revision. A cached revision is not enough evidence that text remains current.
- Read a stable text snapshot: read the count, fetch string text, and read the count again. If it changed, discard the read and retry through the next scheduled evaluation. Bound immediate retries to avoid a hot loop.
- Scan only nonempty text with `detectFast` and the current active packs. A non-string clipboard is not an OCR/file-redaction request. Clean/empty/non-string changes clear the sensitive snapshot and hide a stale overlay.
- Perform expensive detection outside the main actor on a project-compatible worker. A `Task` around synchronous work alone does not satisfy this requirement.
- Tag jobs with monitor lifecycle, clipboard revision and pack configuration version. Reject results if any required version changed, the monitor paused/stopped, or newer text superseded the job.
- Permit at most one running scan and one latest pending snapshot; replace older pending work. Do not accumulate clipboard history in a work queue.
- Recheck frontmost app, effective membership and policy action when accepting results. A job that began in Chrome must not show a Chrome warning after the user switched to another app.

### CL2 · Eligibility and deduplication

An app-level warning requires all of the following:

1. Monitoring is active and current text has findings.
2. The current frontmost bundle ID is in effective coverage.
3. The snapshot/configuration is current.
4. That warning key has not already received a warning.

Maintain a set of warned bundle IDs for the current clipboard revision. Chrome then Dia gets two warnings; Chrome again gets none. Multiple Chrome windows/profiles get one. Copying the same text again resets that set because the change count advanced.

Ignoring, dismissing or auto-hiding a warning consumes that app's warning for the revision. Changing tabs, running discovery, opening Settings or switching to an unprotected app does not reset the set.

Pause hides the overlay, cancels/invalidates scans and releases controller-cached clipboard content. An already-running synchronous worker may retain its input until it returns; discard that result and release its snapshot at completion. Inspecting `changeCount` while paused is allowed, but automatic string reads are not. Keep only non-content dedup/accounting markers for the last revision. On resume, a new revision starts a new incident; an unchanged revision retains prior per-app suppression while receiving a fresh scan.

Pause stops automatic monitoring. The existing global **Paste redacted** shortcut remains a deliberate user action, including while paused or in an unprotected app. It can read/redact current text when invoked, but does not resume watching or create a caught-incident event by itself. Track its explicit-action work separately from automatic scan invalidation.

Membership or pack changes trigger reconciliation. They do not themselves create a new clipboard revision or clear prior warnings/counts. Newly eligible apps can warn for the current revision. Refresh findings with new packs; a visible warning can update its summary without adding an incident.

### CL3 · Overlay destination

- Use the existing non-activating panel, 12 s dismissal, safe-paste action and Reduce Motion support.
- Use the actual destination label, not a hardcoded Chrome string.
- If a different, not-yet-warned protected app becomes frontmost, replace the overlay with that app's validated trigger and restart its existing timeout.
- Hide an app-specific overlay when its destination loses focus, an external clipboard change occurs, monitoring pauses or that app loses coverage. A consumed warning stays consumed. A confirmed Gel-originated block write can retain the frozen block alert for its normal timeout; it must not erase its own explanation.
- The overlay must not steal focus from the browser input. Render from immutable trigger data; do not enumerate applications in the view's `body`.

### CL4 · Block and safe-paste correctness

Evaluate blocking action for current findings before warning deduplication. If a configuration change newly requires blocking in an already-warned app, redact the current clipboard without creating a second counted incident or resetting warning suppression.

For a normal block trigger:

1. Capture an immutable trigger snapshot with original findings, summary and category counts.
2. Produce redacted text for that exact input/findings pair.
3. Before writing, verify the revision, active destination, current configuration and action again. If they changed, abandon the action and reconcile the latest state.
4. Replace the clipboard and mark that exact successful write as Gel-originated.
5. Use the preserved snapshot for the overlay and first-incident event group. Clearing live clipboard caches must not erase counts or summary.

A confirmed write receipt identifies its source and resulting revisions. Commit the original trigger's warning/accounting plan before retiring its ledger revision; use that receipt to distinguish the expected own change from a newer external copy. Do not reject a valid block snapshot merely because its own write advanced the pasteboard count, or commit an unconfirmed write as a successful block.

For safe paste, read/revalidate the current clipboard rather than trusting an old alert's text. Never overwrite a newer copy with a prior alert's redaction. If redaction runs asynchronously, validate the source revision again before writing. If freshness cannot be established, do not synthesize paste; ask the user to retry.

Own-write suppression tracks the exact observed write/revision in memory. A placeholder-looking string copied by another app is not automatically exempt; remove reliance on the `_1]` substring heuristic for provenance. If another process changes the pasteboard during/after the write, reconcile it as external text instead of suppressing it.

After a successful block/safe-paste replacement, the original sensitive revision no longer supplies future browser warnings. Clear its text/findings and treat the exact own write as handled. A new external copy starts fresh tracking.

If clipboard writing fails, do not claim that Gel blocked the paste or synthesize ⌘V. Show non-content guidance to retry. Suppress automatic repeated failure popups for the same revision/app until an explicit retry, relevant state change or new revision.

The pasteboard has no transaction combining external writes with Gel's check-and-write sequence. Freshness checks prevent stale cached actions; they do not prove that no other process can race the write. Do not describe them as atomic interception.

The existing global safe-paste hotkey remains an explicit user action and retains its permission fallback. This feature does not redesign hotkey registration outside watched apps.

## 5. Incident accounting

### A1 · Count once, warn in each app

For the first validated warning/block trigger of a sensitive clipboard revision:

- Emit one existing `leak_caught` event with the first triggering app's display label.
- Emit `leak_item` events with category counts from the frozen first-trigger snapshot.
- Keep this group adjacent in the existing event path before posting the activity-change notification. Use the existing Store serialization lock across the group so a background writer cannot interleave unrelated events between its rows; this requires a small grouped-write API, not a schema or durability redesign.
- Mark the revision accounted for in memory. Subsequent app warnings emit no additional event group or destination-only record.

Do not log a caught incident merely because detection found sensitive text while no protected app was active. Detection alone, discovery, pause, clean text and manual coverage edits produce no caught incident.

The first-trigger snapshot remains the historical count for that copied item. Later pack/configuration changes can change live protection, but they do not rewrite the logged snapshot or add item counts for the same revision. Copy again to start another incident.

App labels can coincide across variants; warning deduplication uses bundle IDs, while existing reports retain their display-name attribution. Do not change the database/report schema in this feature.

### A2 · Session boundary and meaning

- Keep incident/warning state in memory for the process session. Restarting Gel with the same sensitive clipboard can warn and count again.
- Do not persist revision markers, clipboard hashes or a hidden cross-session ledger to avoid that count.
- Home/DPO totals represent detected clipboard incidents/items, not verified unique people, confirmed transmissions or proof of prevented leakage.
- Preserve counts-only storage. No source filenames, clipboard text, snippets, TIN values, placeholder mappings, tab names or URLs enter events/reports.
- This feature preserves the existing Store durability contract; it does not claim transactional recovery or exactly-once accounting after a crash/database failure.

## 6. Timing, permission and privacy requirements

These are implementation acceptance targets, not measurements of the current app:

- With membership cached and the detector warmed, copying the small synthetic TIN fixture or activating a protected app shows the warning within 1 s.
- A newly launched/discovered app should reach usable coverage within 3 s on the verification Mac; once discovery commits, warning evaluation uses the normal 1 s target. Record observed cold/warm times separately.
- A full discovery request should finish within 2 s in the ordinary installed-app fixture. Slower results must leave the UI responsive and prior coverage active; they must not block the clipboard poll.
- Pure membership lookup is cached and does no filesystem or registration work. Preserve the 0.5 s polling interval.
- Discovery/clipboard scanning requires no new permission prompt. Accessibility remains optional for synthesizing paste; without it, put redacted text on the clipboard and show the existing ⌘V guidance.
- Wi-Fi off, Ollama stopped and no indexed folder must not disable discovery or clipboard protection.
- No feature-originated network requests, remote telemetry or cloud fallback. App/browser traffic unrelated to Gel is not this feature's traffic.

## 7. Acceptance criteria

All criteria remain unchecked until implementation verification. Use [verification.md](verification.md) for fixtures, test cases and walkthroughs.

| ID | Criterion | Required evidence |
| --- | --- | --- |
| AC01 | Discover HTTP-only and HTTPS-only registered apps without default-browser dependence. | Fake-provider tests and native adapter check |
| AC02 | Discover a launched non-static browser from HTTP/HTTPS bundle evidence; no restart required. | Adapter fixture and app walkthrough |
| AC03 | Merge/deduplicate handler, known and manual evidence by exact bundle ID; retain channel IDs separately. | Pure tests |
| AC04 | Skip malformed/stale/non-app candidates without crashing or losing valid candidates. | Adapter fixtures |
| AC05 | Empty/failed/partial discovery retains the appropriate fallback or last usable coverage and honest status. | Refresh tests and Settings check |
| AC06 | Nil, empty and explicit policy lists have the exact C1 precedence; duplicate policy IDs cannot trap. | Pure tests |
| AC07 | Coverage edits persist IDs only; managed edits cannot override an explicit policy. | Isolated settings tests and app check |
| AC08 | Refresh handles launch, unknown activation, Settings, manual refresh and wake without poll-path enumeration. | Fake-clock/lifecycle harness |
| AC09 | Stale or stopped discovery results cannot overwrite current state; latest policy resolves completed results. | Deferred-provider harness |
| AC10 | A preexisting clipboard is checked on start and after paused copies on resume. | Clipboard harness and app check |
| AC11 | Warn once in Chrome and once in another protected browser for one revision; no repeat on returning. | Ledger tests and app walkthrough |
| AC12 | Re-copying identical text starts fresh warnings; windows/profiles of one bundle do not. | Ledger tests and app check |
| AC13 | One revision produces one count group attributed to its first triggering app, including block-mode items. | Ledger/event-sink tests and scratch-store check |
| AC14 | Block mode preserves nonempty summary/counts and makes a subsequent normal paste use redacted text. | Snapshot tests and synthetic input check |
| AC15 | Changed clipboard/app/configuration invalidates stale scan/redaction actions before writes/events. | Controlled-race harness |
| AC16 | Gel-originated writes do not loop; external placeholder-looking copies still undergo detection. | Clipboard provenance harness |
| AC17 | Clean/empty/non-string clipboard and unprotected apps produce no caught events or stale app overlay. | Harness and app check |
| AC18 | Pause stops automatic clipboard-content reads/actions; resume scans current text while retaining unchanged-revision dedup. Explicit safe paste remains a user action. | Harness and app check |
| AC19 | The Settings catalog explains sources, status, incomplete discovery, empty managed lists and editable versus managed controls. | Design walkthrough |
| AC20 | Add/exclude/reenable/remove flows follow C2, including a policy change while a sheet is open. | Settings harness and app check |
| AC21 | Missing/reinstalled apps keep user IDs; a new discovered current app is evaluated without a recopy. | Metadata/refresh harness |
| AC22 | Existing chat-app/default coverage and global safe-paste permission fallback remain available. | Regression walkthrough |
| AC23 | No new permission request or network traffic; no clipboard/path inventory data in persisted events/preferences/reports. | Code/storage review and offline check |
| AC24 | Cached warnings and discovery meet the timing targets with recorded measurements; a missed target remains pending/failed. | Timed walkthrough |
| AC25 | Coverage/scan services start once, stop cleanly and reject callbacks after teardown. | Lifecycle harness |
| AC26 | Native controls remain keyboard/VoiceOver accessible; overlay stays non-activating and respects Reduce Motion. | App accessibility check |

## 8. Approval and rollout

The user has confirmed the scope and questionnaire decisions. The exact written specification still needs review before app work begins. Implement behind the task sequence, preserve existing settings for rollback, and mark criteria/tasks complete only after observing their required evidence. This documentation change alone does not satisfy any runtime criterion.
