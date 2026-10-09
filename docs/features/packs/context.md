# F7 · Packs — Context

## Why it exists

Judges reward a clear target user, so the demo is HR; but Gel is a platform. Packs show that in 20 seconds (demo beat 5: switch to Personal, a passport number gets caught) and are the B2B/B2C expansion story ([product](../../project/product.md), [decisions D-006](../../project/decisions.md)).

## Where it sits

- **Upstream:** bundled JSON in `GelCore/Resources/`, custom JSON in `Application Support/Gel/Packs/`, `GelSettings.activePacks`, policy `requiredPacks` ([policy-dpo-report](../policy-dpo-report/spec.md)).
- **Downstream:** [detection-redaction](../detection-redaction/spec.md) (layer 1 patterns), [leak-guard](../leak-guard/spec.md), [onboarding](../onboarding/spec.md) and [settings](../settings/spec.md) (toggles), [app-shell](../app-shell/spec.md) (menu bar Pack submenu).

## Current state

Built:

- `Gel/GelCore/PII/PIIDetector.swift`: `PIIType`, `Pack`, `PackStore` (`reload`, `packs`, `selectablePacks`, `types(active:)`).
- `Gel/GelCore/Resources/pack_core.json` (always on: EMAIL, PHONE, DOB, ADDRESS ×2), `pack_hr.json` (PHILSYS, SSS, PHILHEALTH, TIN, PAGIBIG, SALARY ×2, BANK_ACCOUNT ×2), `pack_personal.json` (PHILSYS, PASSPORT, DRIVERS_LICENSE, BANK_ACCOUNT ×2, GCASH, CARD, AMOUNT ×2).
- `GelSettings.activePacks` (UserDefaults, default `["hr"]`).
- Unit tests exercising HR and Personal patterns pass.

**Not built:** onboarding picker, Settings toggles, menu bar submenu, policy-forced packs, a custom-pack loading test.

## Facts and gotchas

- Resources are bundled flat into `GelCore.framework`; `PackStore` finds them by the `pack_` filename prefix.
- Custom packs load after bundled ones, so the same `id` overrides the bundled pack.
- `types(active:)` de-duplicates by `id + pattern`, so the same type in two packs isn't run twice.
- `PackStore.shared` loads once at first use; call `reload()` after dropping in a new file.
- OCR variants (`P18.000.00`, bare `###-####-###` accounts) live in the packs, not in Swift ([D-013](../../project/decisions.md)).

## Related

[spec](spec.md) · [tasks](tasks.md) · [interfaces](interfaces.md) · [detection-redaction](../detection-redaction/spec.md)
