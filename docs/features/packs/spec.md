# F7 · Packs — Spec

**Goal:** the same engine serves HR teams and consumers by switching configuration, not code.

## Pack format (`pack_<id>.json`)

```json
{
  "id": "hr", "name": "HR", "description": "…", "audience": "Work", "alwaysOn": false,
  "types": [
    { "id": "SSS", "label": "SSS number", "category": "government ID",
      "pattern": "(?<![\\d-])\\d{2}-\\d{7}-\\d(?![\\d-])", "group": 0, "validator": null }
  ],
  "sampleQuestions": ["Sino sa applicants ang may 5+ years sa payroll?"]
}
```

- `category` drives summaries and reports: `government ID`, `salary`, `bank account`, `card`, `money`, `address`, `date of birth`, `contact`, `name`, `health`, `other`.
- `group` picks a capture group for context patterns (e.g. "Account No.: <value>"). `validator: "luhn"` filters card numbers.
- A type id may appear more than once (several patterns for one type).

## Loading

- Bundled packs: `GelCore/Resources/pack_core.json` (always on), `pack_hr.json`, `pack_personal.json`.
- Extra packs: any `*.json` in `Application Support/Gel/Packs/` (a new pack needs no code change). Same id overrides the bundled pack.
- Active packs: `GelSettings.activePacks` (default `["hr"]`), union of their types plus the always-on packs. The policy's `requiredPacks` are forced on and locked ([policy-dpo-report](../policy-dpo-report/spec.md)).

## UI

- **Onboarding** (first launch, one screen): "Who is this for?" → **Work: HR** or **Personal** (or both) → sets active packs → pick the folder.
- **Switching:** Settings → Packs (toggles) and the menu bar → Pack submenu. Takes effect immediately for Leak Guard and the next detection; no restart.

## Acceptance criteria

- [ ] Switching HR → Personal changes what Leak Guard flags without restarting.
- [ ] With Personal on, the passport + bank clipboard sample yields "1 passport number…" style findings for both the passport and the account.
- [ ] Dropping a test pack JSON into `Application Support/Gel/Packs/` adds its types after `PackStore.reload()` (unit-testable with `GEL_HOME`).
