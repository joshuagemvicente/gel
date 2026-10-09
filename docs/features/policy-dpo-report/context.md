# F8 · Team policy and DPO report — Context

## Why it exists

B2B is the priority ([product](../../project/product.md)). Under the Data Privacy Act every organization processing personal data appoints a Data Protection Officer ([context](../../project/context.md)). A policy file (admin control) plus a counts-only report (evidence) turns Gel from a personal tool into something companies would pay for. Demo beat 4 shows "locked to block by the company policy" and a one-click export ([demo-and-submission](../../project/demo-and-submission.md)).

## Where it sits

- **Upstream:** `policy.json` in `Application Support/Gel/` (or `$GEL_HOME`); events written by [query-citations](../query-citations/spec.md), [leak-guard](../leak-guard/spec.md), [redactions-module](../redactions-module/spec.md) and [model-fallback](../model-fallback/spec.md).
- **Downstream:** [leak-guard](../leak-guard/spec.md) (watched apps, warn/block), [packs](../packs/spec.md) (required packs), [model-fallback](../model-fallback/spec.md) (cloud allowed), [settings](../settings/spec.md) (locked controls, install/remove sample), [home](../home/spec.md) (`DPOReport.totals`), [redactions-module](../redactions-module/spec.md) (Export report).

## Current state

Built in `Gel/GelCore/Policy/TeamPolicy.swift`: `TeamPolicy` (`load`, `action(for:)`, `blocks(_:)`, `sample`), `LeakGuardDefaults.watchedApps`, `DPOReport` (`csv(since:)`, `Totals`, `totals(since:)`, `export(since:organization:)`, PDF writer). `GelPaths.policy` and `GelPaths.reports` in `Support/Settings.swift`. `ModelRouter.cloudAllowedByPolicy` exists but nothing sets it yet.

**Not built:** applying the policy at launch, locked-settings UI, install/remove sample, block mode in Leak Guard, the Export button, a content-leak check of the exported files.

## Facts and gotchas

- Event kinds: `query` (provider), `leak_caught` (app), `leak_item` (category, count), `redaction`, `redaction_item` (category, count), `cloud_call` (count = payload characters). Today only `query` and `cloud_call` are logged by GelCore; the leak and redaction kinds are logged by the app (not built yet), so totals read 0 until then.
- `DPOReport.csv` groups by date|event|category|app|provider and counts `cloud_call` rows as 1 each (not characters).
- `action(for:)` checks the type id first, then the category; default `"warn"`.
- The sample policy blocks `government ID`, `salary`, `bank account`, requires `hr`, allows cloud fallback.
- The PDF summary is drawn with AppKit text on a CGContext (US Letter); keep it to one page.

## Related

[spec](spec.md) · [tasks](tasks.md) · [interfaces](interfaces.md) · [leak-guard](../leak-guard/spec.md)
