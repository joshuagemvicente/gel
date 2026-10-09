# F5a · Automatic browser discovery — Context

## Why this feature exists

The user wants Gel to protect copied personal data when they open any browser on their Mac, including Dia and future browsers, without maintaining a growing list of names.

The current implementation already lists Chrome, Safari, Arc, Edge, Brave and Firefox. It does not discover additional browsers. Its global one-warning-per-clipboard-change gate can also make a multi-browser test appear Chrome-only: a warning in Chrome prevents another warning for that same copied item in Safari.

The folder containing the source document does not affect clipboard protection. An indexed file, an unindexed document and text copied from another app follow the same detection path.

## Current implementation: code inspection, not app verification

| Area | Current state | Source |
| --- | --- | --- |
| Static coverage | Six browser IDs, two AI desktop apps and other chat-app IDs; no browser discovery service | `Gel/GelCore/Policy/TeamPolicy.swift` |
| Policy | `watchedApps == nil` uses defaults; a present list replaces them; `[]` watches nothing | `Gel/GelCore/Policy/TeamPolicy.swift`; monitor's `watched` property |
| Polling | Every 0.5 s; an activation notification also requests evaluation | `Gel/Gel/LeakGuard/LeakGuardMonitor.swift` |
| Deduplication | `alertedForChange` suppresses subsequent warnings across all apps for one change | `Gel/Gel/LeakGuard/LeakGuardMonitor.swift` |
| Startup | `lastChange` starts at the existing change count; existing text receives no initial scan | Same monitor |
| Pause/resume | Menu bar toggles a boolean; resume has no explicit current-clipboard scan | `Gel/Gel/App/AppDelegate.swift`; same monitor |
| Block accounting | `setClipboard` clears findings before the monitor builds category events and the summary | Same monitor, `evaluate` and `setClipboard` |
| Freshness | Activation and safe paste can use cached text before the next poll observes a newer copy | Same monitor |
| Lifecycle | AppDelegate owns and starts the monitor after AppState startup; no implemented idempotent stop/teardown | `Gel/Gel/App/AppDelegate.swift`; same monitor |
| Preferences | Injectable `GelSettings(defaults:env:)`; default app suite is `com.joshuagemvicente.gel` | `Gel/GelCore/Support/Settings.swift` |
| Settings | Native scrolling cards; no app-coverage editor | `Gel/Gel/Settings/SettingsView.swift` |
| Audit | `leak_caught` and category-count `leak_item` events; reports aggregate these existing event kinds | `Gel/GelCore/Index/Store.swift`; `Gel/GelCore/Policy/TeamPolicy.swift` |
| Tests | XCTest target depends on GelCore, not the app; isolated UserDefaults precedent already exists | `Gel/project.yml`; `Gel/GelCoreTests/FolderListTests.swift` |

Several original feature contexts describe app pieces as unbuilt despite existing implementations. Use the code paths above for the baseline; do not interpret stale interface sketches as implemented APIs.

## Platform facts

Verified against Apple's documentation and the installed AppKit SDK headers on 2026-10-10:

- `NSWorkspace.urlsForApplications(toOpen: URL)` returns registered apps capable of opening the supplied URL. The API is available from macOS 12, within Gel's macOS 15 target.
- `urlForApplication(toOpen:)` returns only the default handler. It is insufficient for discovering other installed browsers.
- `frontmostApplication` identifies the app receiving keyboard events. `didActivateApplicationNotification` arrives through `NSWorkspace.shared.notificationCenter`.
- `didLaunchApplicationNotification` and `didWakeNotification` provide refresh opportunities without a filesystem inventory scan.
- A running app provides bundle identity/URL metadata. `CFBundleURLTypes` / `CFBundleURLSchemes` describe schemes an app declares, such as `http` and `https`.
- URL-handler registration supplies capability evidence, not proof that an app is a browser. Link-routing apps can qualify. Installed apps that only embed a web view may not qualify.
- A URL-handler lookup does not require opening that URL. Use fixed synthetic `.invalid` URLs and never call an opening or default-handler-setting API during discovery.

### Primary references

- [NSWorkspace.urlsForApplications(toOpen:)](https://developer.apple.com/documentation/appkit/nsworkspace/urlsforapplications(toopen:)-ualk)
- [NSWorkspace.didActivateApplicationNotification](https://developer.apple.com/documentation/appkit/nsworkspace/didactivateapplicationnotification)
- [CFBundleURLTypes](https://developer.apple.com/documentation/bundleresources/information-property-list/cfbundleurltypes)
- [Apple information-property-list reference](https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html)
- Local verification source: AppKit's `NSWorkspace.h`, `URLsForApplicationsToOpenURL:` and notification declarations in the installed macOS SDK.

## Integration boundaries

- New pure models/resolution/accounting logic belong in GelCore, with no SwiftUI or native clipboard dependency.
- AppKit discovery, pasteboard access, observers and panel ownership belong in the app target.
- AppState publishes coverage/status for Settings and notifies the monitor when relevant configuration changes.
- Keep the existing company-policy schema and report event format. Fix duplicate-ID handling in the membership resolver without rewriting policy loading or cloud controls.
- Preserve a frozen trigger snapshot before replacing the clipboard. This is a prerequisite for the agreed first-incident accounting, not a general redaction refactor.
- Keep existing global hotkey registration outside this scope. Freshness checks apply to writes made through the existing safe-paste handler; broader hotkey conflicts/scoping need a separate brief.

## Deferred baseline issues

This feature does not repair malformed-policy fallback, redesign database durability, expand detection patterns, fix every global shortcut conflict, or add paste interception. The app can still miss a very fast paste before its reactive detector finishes. The specification requires honest copy about that boundary.
