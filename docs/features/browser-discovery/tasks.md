# F5a · Automatic browser discovery — Tasks

**Status:** implementation not started. Every task below remains open; creating this folder does not complete an implementation task.

Legend: `[x]` implemented and verified · `[~]` implemented, required verification pending · `[ ]` not started.

Read [spec.md](spec.md), [interfaces.md](interfaces.md), [design.md](design.md) and [verification.md](verification.md) before starting. Proposed filenames describe new work; they do not claim those files already exist.

## T0 · Approve the written brief

- [ ] **T0 Written-spec approval.** Walk the written contract with the user, especially managed empty lists, handler-versus-browser evidence, session-only counts and reactive-paste limits. Obtain explicit approval for implementation, separate from approval to create documentation.
  - **Depends on:** none.
  - **Verify:** user approves the written brief and app implementation; record any changes in this folder before coding.

## T1 · Pure identity, qualification and membership

- [ ] **T1 Coverage engine.** Add value models and a pure resolver under `Gel/GelCore/Policy/`, with proposed files `AppProtection.swift` and `AppProtectionResolverTests.swift` under `Gel/GelCoreTests/`.
  - Implement BD1/BD2 qualification facts and exact-ID normalization/deduplication. Avoid forcing IDs to lowercase or inferring them from names.
  - Implement C1 nil/empty/explicit policy precedence, unknown policy IDs, fallback membership and separated display availability.
  - Write failing resolver tests before binding the monitor to the new resolver. Preserve known chat-app coverage.
  - **Depends on:** T0.
  - **Verify:** membership/qualification matrix R01–R14 passes, including duplicate policy IDs and exclusions overlapping manual/default sources. Regenerate with XcodeGen after adding sources.
  - **Criteria:** AC01, AC03, AC04, AC06, AC22.

## T2 · ID-only preferences and edits

- [ ] **T2 User coverage settings.** Add the two properties to `Gel/GelCore/Support/Settings.swift` and pure edit operations to the resolver. Add isolated preference/edit XCTest coverage.
  - Start with empty ID arrays on upgrade; persist normalization and nothing else.
  - Apply Add/exclude/reenable/remove semantics, including explicit-policy rejection and clearing an exclusion on manual add.
  - Keep unrelated or concurrent settings changes intact.
  - **Depends on:** T1.
  - **Verify:** S01–S08 passes with a unique injected UserDefaults suite. Inspect suite contents for ID arrays only; prove nil app policy does not lock edits and an explicit empty list does.
  - **Criteria:** AC07, AC20, AC23.

## T3 · Native app evidence

- [ ] **T3 Discovery adapter.** Add the app-target adapter under `Gel/Gel/LeakGuard/`, with a proposed `BrowserDiscoveryService.swift` or adjacent native provider file.
  - Query both fixed synthetic web URLs without opening them. Read running-app bundle metadata and known-ID installation evidence.
  - Apply the same pure qualification path to query and running-app evidence. Preserve duplicate-source provenance and deterministic labels.
  - Skip malformed/unreadable/non-app candidates and represent partial/empty results truthfully.
  - Keep metadata work out of the clipboard poll and SwiftUI body; cache evidence in memory only.
  - **Depends on:** T1.
  - **Verify:** native evidence cases D01–D05 and actual NSWorkspace adapter inspection pass. Confirm no URL opens, default-handler mutation or new permission request. A non-static web-link fixture qualifies without adding a guessed Dia ID.
  - **Criteria:** AC01–AC05, AC23.

## T4 · Refresh coordinator and service lifecycle

- [ ] **T4 Refresh scheduling.** Wire startup, launch, unknown activation, Settings/manual refresh and wake signals through one bounded coordinator.
  - Retain observer tokens and owned work; implement idempotent start/stop, request/lifecycle validation, 250 ms burst debounce and the 30 s unknown-ID miss cooldown.
  - Permit one in-flight full request and one pending refresh. Preserve usable coverage on real failure; resolve completion against current policy/preferences.
  - Expose published discovery status and immutable catalog values for AppState/Settings.
  - **Depends on:** T2, T3.
  - **Verify:** fake-clock/deferred-provider D06–D14 passes. Repeated start installs one observer set; completion after stop publishes nothing; repeated clipboard polling performs zero full-discovery calls.
  - **Criteria:** AC05, AC08, AC09, AC21, AC25.

## T5 · Revision ledger and stale-result decisions

- [ ] **T5 Pure clipboard state.** Add the ledger/version decisions to GelCore and regression tests, with proposed files `ClipboardIncidentLedger.swift` and `ClipboardIncidentLedgerTests.swift`.
  - Separate plan from validated commit. Track warned app IDs and one first-count marker for the current external clipboard revision.
  - Keep process-session identity, lifecycle and pack-version validation explicit; preserve unchanged-revision markers through pause/service restart.
  - Treat an exact own write as handled. Do not use clipboard text or hashes as identity or keep a history of revisions.
  - **Depends on:** T0.
  - **Verify:** L01–L14 passes, including identical re-copy, two browser IDs, profiles sharing an ID, stale commit rejection, pending cancellation and restart semantics.
  - **Criteria:** AC10–AC13, AC15–AC18, AC25.

## T6 · Fresh clipboard monitoring and deterministic harness

- [ ] **T6 Monitor orchestration.** Update `Gel/Gel/LeakGuard/LeakGuardMonitor.swift` to consume the coverage snapshot and ledger. Build a DEBUG-only isolated harness around the production orchestration seams before applying the behavioural changes.
  - Scan existing text on start/resume. Reconcile before activation/configuration actions; perform stable count/string/count reads.
  - Move expensive fast detection onto a bounded worker, capture configuration values and invalidate stale completions.
  - Hide stale app overlays on clipboard/focus/pause/coverage changes, without resetting consumed warning keys.
  - Test through fake pasteboard, app, detector, overlay and scheduler adapters, not sleeps or a duplicate implementation.
  - **Depends on:** T1, T4, T5.
  - **Verify:** controlled scenarios C01–C05, C09 and C10 go red before the applicable fix and green afterward. The harness never touches the live clipboard, app settings or store. Native startup/resume and focus walkthroughs remain separately required.
  - **Criteria:** AC10–AC12, AC15, AC17, AC18, AC25, AC26.

## T7 · Block/safe-paste snapshot and write provenance

- [ ] **T7 Redaction correctness.** Preserve an immutable trigger snapshot before replacing the clipboard; validate source revision/destination/configuration before writes. Integrate exact own-write suppression and failure handling.
  - Lock down the current empty block-summary/category-count failure with a regression scenario before changing the action order.
  - Replace the placeholder-substring exemption with confirmed in-memory provenance.
  - Revalidate the latest clipboard when safe paste runs; abort stale/failed writes and avoid synthesized paste on those paths.
  - Keep Accessibility fallback and global hotkey registration unchanged.
  - **Depends on:** T6.
  - **Verify:** C06–C08 and C11–C13 pass. Block then normal paste contains placeholders and original nonempty summary/counts; an old alert cannot overwrite a newer copy. Record the remaining check/write race limitation.
  - **Criteria:** AC14–AC16, AC22, AC23.

## T8 · One-incident events and presentation

- [ ] **T8 Accounting integration.** Bind committed first-trigger snapshots to existing Store/Home/report paths without schema changes.
  - Emit one adjacent `leak_caught`/`leak_item` group, attributed to the first triggering app; later app warnings emit none.
  - Add the small grouped writer in `Gel/GelCore/Index/Store.swift`, holding its existing recursive lock for the group. Test adjacency under another writer; do not redesign transaction durability or unrelated Store operations.
  - Preserve category counts after block writes and publish activity change after the count group.
  - Keep historical first-trigger counts stable across pack/action/catalog changes; session restart remains a fresh ledger.
  - **Depends on:** T5, T7.
  - **Verify:** event-spy assertions and an isolated Store verify the exact one-TIN totals and grouped-write adjacency. Manual Chrome → another browser leaves Home/DPO totals unchanged after the first trigger. Search persisted data for synthetic fixture contents and paths; none may appear in this feature's records.
  - **Criteria:** AC13, AC14, AC23.

## T9 · Settings coverage controls

- [ ] **T9 Native coverage UI.** Add the card and row states from `design.md` through AppState's published service values.
  - Implement Refresh, native Add app picker, exclusion/reenable, remove manual entry and missing-app/exclusion visibility.
  - Keep explicit app-policy controls locked while distinguishing a policy whose app list is nil. Recheck authority when sheets return.
  - Use installed/running availability for counts, not the size of the fallback ID map. Preserve focus/scroll and existing voice/hotkey settings.
  - **Depends on:** T2, T4, T6, T7.
  - **Verify:** S01–S08 plus manual M04–M07 and M11 pass. Use long names, a missing manual app, explicit empty policy, nil-list organization policy and a policy change during a sheet. Complete keyboard/VoiceOver checks.
  - **Criteria:** AC07, AC19–AC21, AC26.

## T10 · Process wiring and regression walkthrough

- [ ] **T10 Application integration.** Start/stop discovery and monitoring through AppDelegate and connect pack/policy/pause changes through AppState. Preserve existing startup/termination work and app lifetime after window closure.
  - Reconcile on wake and relevant configuration changes without resetting the current incident.
  - Make a just-discovered frontmost browser eligible without another copy. Discovery completion uses the actual current app, not the app that requested the scan.
  - Retain existing known AI/chat coverage and non-activating overlay behaviour.
  - **Depends on:** T4, T7, T8, T9.
  - **Verify:** M01–M03, M08–M10 and M12–M14 pass; lifecycle harness proves teardown/restart and pending-result rejection. Verify no folder/Ollama/network dependency.
  - **Criteria:** AC02, AC08–AC18, AC21–AC26.

## T11 · Build, evidence and handoff

- [ ] **T11 Final verification.** Regenerate the project, build Gel and gelcli, run GelCoreTests and the app-target scenario harness, then execute the manual matrix with synthetic data.
  - Use commands from [project conventions](../../project/conventions.md) and the isolation instructions in `verification.md`.
  - Record measured timing, tested browser/version/OS, results and pending unavailable-browser checks. Do not convert unavailable checks to passes.
  - Review the diff for clipboard content, app inventories, secrets and generated project/build outputs. Keep unrelated changes untouched.
  - Update this folder's current state and verified task/criterion status. Update the parent Leak Guard/Settings planned-extension references only after observing implementation verification.
  - **Depends on:** T1–T10.
  - **Verify:** required builds/tests/harness cases pass; every acceptance criterion has evidence or remains pending. Handoff names changed files, failures and unrun checks. Commit only if the user asks.
  - **Criteria:** AC01–AC26.
