# U4 · Settings — Context

## Why it exists

Settings is where the user points Gel at their folder, chooses packs, and enters the cloud fallback endpoint they will supply (a Claude model behind an OpenAI-compatible gateway). It's also where the demo installs the sample company policy that turns warnings into blocks (demo step 4). It serves **Technical Execution (20%)**: the fallback must be configurable without touching code.

## Where it sits

- **Upstream:** `GelSettings` (UserDefaults + Keychain + env overrides), `PackStore`, `TeamPolicy`, `ModelRouter` (`localIsHealthy`, `warmUp`, `cloudClient`), `OpenAICompatibleClient.listModels()`, `Indexer`.
- **Downstream:** every feature reads these settings; packs affect detection and Leak Guard immediately.

## Current state

- Nothing built in the app target.
- Engine ready: all `GelSettings` properties (`folderPath`, `localModel`, `embedModel`, `cloudEnabled`, `cloudBaseURL`, `cloudModel`, `cloudAPIKey`, timeouts, `activePacks`, `onboardingDone`), `TeamPolicy.load()/sample`, `GelPaths.policy`.

## Facts and gotchas

- The user will give the endpoint URL, key and model during the build; they enter them here. Keys never go in chat, code or the repo.
- Env vars `GEL_CLOUD_BASE_URL/API_KEY/MODEL` override the stored values (for terminal testing); the UI should show "Overridden by environment" when they're set.
- Accessibility status: `AXIsProcessTrusted()`; prompt with `AXIsProcessTrustedWithOptions`. Deep link: `x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility`. Microphone: `AVCaptureDevice.authorizationStatus(for: .audio)`; deep link `…?Privacy_Microphone`.
- Ad-hoc signed debug builds may lose Accessibility trust after a rebuild; Settings should make re-granting obvious.
- Writing the sample policy = encode `TeamPolicy.sample` to `GelPaths.policy`; then reload policy in `AppState`.

## Related docs

[spec](spec.md) · [design](design.md) · [tasks](tasks.md) · [model-fallback](../model-fallback/spec.md) · [packs](../packs/spec.md) · [policy-dpo-report](../policy-dpo-report/spec.md)
