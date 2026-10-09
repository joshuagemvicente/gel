# F8 · Team policy and DPO report — Spec

**Goal:** make Gel something an organization can deploy and audit: admin-controlled behaviour plus counts-only evidence for the Data Protection Officer.

## Policy file

`Application Support/Gel/policy.json` (later via MDM). Decoded as `TeamPolicy`:

| Field | Type | Effect |
| --- | --- | --- |
| `organization` | string | Shown as "Managed by <organization>" on locked settings and in block messages |
| `requiredPacks` | [string]? | Forced on; their toggles locked |
| `watchedApps` | [bundle id]? | Replaces Leak Guard's default app list |
| `actions` | {type-or-category: "warn" \| "block"}? | Per data type id first, then category; default `warn` |
| `allowCloudFallback` | bool? | `false` disables the cloud fallback and locks its settings (`ModelRouter.cloudAllowedByPolicy`) |

- Loaded at launch and when Settings opens. No policy file = unmanaged (everything editable).
- Settings → "Install sample policy" writes `TeamPolicy.sample` (Bayanihan Outsourcing Corp.; HR required; government ID, salary, bank account = block) for the demo, and "Remove policy".

## DPO report

- Redactions & Leak Guard → **Export report**, with a date range (default: last 30 days).
- Writes `Gel-DPO-report-<date>.csv` (date, event, category, app, provider, count) and a one-page PDF summary to `Application Support/Gel/Reports/`, then reveals them in Finder.
- Contents: leaks caught, items kept on device, files redacted, local vs cloud answers, totals by category. **Never** content, file names or clipboard text.

## Acceptance criteria

- [ ] With the sample policy installed, the HR pack toggle and cloud settings governed by it are locked and labelled "Managed by Bayanihan Outsourcing Corp.".
- [ ] A blocked category can't be pasted raw into a watched app ([leak-guard](../leak-guard/spec.md) block mode).
- [ ] The exported CSV and PDF contain none of the ground-truth values or file names (scripted check).
