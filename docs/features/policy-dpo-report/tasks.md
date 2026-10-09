# F8 · Team policy and DPO report — Tasks

Legend: `[x]` done and verified · `[~]` built, not verified · `[ ]` not started.

- [~] **T1 `TeamPolicy` model + loading.** Files: `GelCore/Policy/TeamPolicy.swift`. **Verify:** unit test (to add, `GelCoreTests/PolicyTests.swift`): encode `TeamPolicy.sample` to `$GEL_HOME/policy.json`, `TeamPolicy.load()` round-trips; `action(for:)` returns `block` for an SSS finding and `warn` for an EMAIL finding.
- [~] **T2 DPO report (CSV, totals, PDF).** Files: `TeamPolicy.swift`. **Verify:** unit test: log a few events into a temp `Store`, `DPOReport.totals` matches; `export` writes a `.csv` and `.pdf` under `GelPaths.reports`.
- [ ] **T3 Apply policy at launch.** `AppState` loads the policy, sets `ModelRouter.shared.cloudAllowedByPolicy = policy?.allowCloudFallback ?? true`, forces `requiredPacks` into `activePacks`. Files: app target ([app-shell](../app-shell/spec.md)). **Verify:** with `allowCloudFallback: false`, `ModelRouter.shared.cloudClient == nil`.
- [ ] **T4 Install/remove sample + locked UI** (owned by [settings](../settings/spec.md)). **Verify:** after install, the HR toggle and cloud controls show "Managed by Bayanihan Outsourcing Corp." and can't be changed.
- [ ] **T5 Block mode** (owned by [leak-guard](../leak-guard/tasks.md) T6). **Verify:** with the sample policy, ⌘V of the employee sample into chatgpt.com pastes placeholders.
- [ ] **T6 Export button** (owned by [redactions-module](../redactions-module/spec.md)). **Verify:** Export reveals both files in Finder.
- [ ] **T7 No-content check.** Script greps both exported files for every `value` in `demo-data/ground_truth.json` and every demo file name. **Verify:** zero matches.

Done when: all [spec.md](spec.md) acceptance criteria observed passing.
