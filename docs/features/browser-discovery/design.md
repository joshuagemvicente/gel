# F5a · Automatic browser discovery — Settings design

**Status:** proposed native UI. The behaviour source of truth is [spec.md](spec.md), especially C1/C2 and CL3. Reuse the existing Settings cards and theme; this feature does not redesign the app shell.

## 1. Placement and hierarchy

Add a **Leak Guard** coverage card near Packs and Permissions in the existing Settings module. Keep Hotkeys, voice controls and other concurrent Settings work intact.

```text
Leak Guard                                      Refresh   Add app…
Protects sensitive copied text in browsers and selected apps.

[status]  Automatic coverage · 4 available apps protected
          Covers every website in a protected browser.
          Gel does not read tabs or webpages.

App                Coverage             Source                 Protect
Safari             Protected            Web-link handler        [on]
Dia                Protected            Web-link handler        [on]
ChatGPT            Protected            Known app               [on]
Example Browser    Not found            Added by you             [on]

Excluded apps [disclosure]
Brave              Excluded             Web-link handler        [off]

Missing an app? Add its .app file or refresh after installing it.
```

Example rows/counts illustrate layout only; render actual app names and counts. Do not ship them as a fake inventory or identify Dia through a guessed static ID.

- Show name and state first. Put bundle ID/source detail in secondary text or a disclosure so similarly named channels remain distinguishable.
- Use stable bundle IDs for row identity. Keep names readable through wrapping/truncation with accessible full labels.
- Count available protected apps, not every fallback ID that might someday be installed. Explain unavailable configured IDs separately.
- Show installed discovered apps plus relevant known apps. Keep manual, explicit-policy and excluded IDs visible when not installed so users can understand retained settings.
- No continuous refresh animation or animated table insertion. Preserve the app's existing restraint around Settings layout animations.

## 2. Global card states

| State | Copy / controls |
| --- | --- |
| Initial refresh, fallback ready | “Finding browsers and web-link apps…” plus “Known and added apps remain covered.” Keep prior/fallback rows usable. |
| Ready, editable | “Automatic coverage” and actual available-protected count; Add app and per-row controls enabled. |
| Refresh in progress | Small bounded progress indication and “Refreshing…”; show existing rows. Coalesce another refresh request without starting parallel work. |
| No discovered web-link apps | “No web-link apps found. Known and added apps still use their coverage settings.” Offer Refresh and Add app. Do not imply no protection if fallback membership exists. |
| Partial/failing discovery | “Couldn't finish finding apps. Existing coverage is kept.” Offer Refresh and Add app; optional non-content detail reason. |
| Leak Guard paused | “Leak Guard is paused. Coverage settings are saved; automatic clipboard checks are off.” Discovery/settings can refresh; the explicit Paste redacted shortcut remains available. |
| Explicit app policy | Lock glyph, “App coverage is managed by <organization>.” Disable app mutations; allow Refresh for metadata. |
| Explicit empty list | “Your organization has not selected any apps for Leak Guard.” Do not auto-enable discovered browsers. |
| Policy exists, app list nil | Explain “Some settings are managed by <organization>. App coverage is automatic.” Coverage controls remain editable. |

The user can expand a secondary section for installed discovered apps excluded by company policy. Label each **Not in company policy**, never Protected. This explains why discovering a browser does not override the administrator.

## 3. Row states and provenance

| Row state | Meaning | Presentation |
| --- | --- | --- |
| Protected / available | In effective membership with usable installed/running evidence | On toggle or managed lock; actual source label |
| Excluded | User exclusion wins over automatic/default/manual evidence | Off toggle; “Excluded by you”; re-enable action |
| Not found | A retained manual/policy ID lacks an installed representative | Secondary “Not found”; preserve configured setting, not a false installed count |
| Availability unknown | Metadata could not be resolved | “Availability unknown”; no promise the app is installed |
| Managed protected | Explicit policy contains this ID | Lock and “Company policy”; user cannot disable it |
| Not in company policy | Catalog finds it, but explicit policy omits it | Disabled off control or status text; no enrollment action |

Source labels: **Web-link handler**, **Known browser**, **Known app**, **Added by you**, **Company policy**. A row can disclose multiple evidence sources; one primary label is enough in the compact layout.

Do not label every handler a browser. A link router can be protected through the same capability evidence. No source label should contain a browser profile, tab, document name or absolute app path.

## 4. Interactions

### Refresh

Request service refresh without blocking Settings. Preserve scroll position, focused row and current overrides. Success updates metadata/membership; it does not reset clipboard-warning history or increment stats.

### Add app…

Use a native NSOpenPanel limited to one application bundle. Treat `.app` as the selectable item; do not let the user browse its internal files as the intended selection. Do not execute the application.

- Valid selection: add the bundle ID and clear its exclusion. Show “<name> is now protected.”
- Already protected: “<name> is already protected.” Reuse the row; do not create duplicates.
- Invalid/missing identity: “Choose an app with a readable bundle identifier.” Keep settings unchanged.
- Cancel: no change.
- Policy became explicit while the panel was open: “App coverage is now managed by <organization>. Your selection wasn't applied.” Do not change saved overrides.

### Exclude and re-enable

Turning Protect off requests a confirmation: **Stop protecting <name>?** Message: “Gel won't warn about sensitive clipboard text in this app. Other apps stay covered.” Buttons: **Stop protecting** and **Cancel**.

Confirming adds an exclusion, immediately recomputes membership and hides that app's active overlay. Cancelling restores the visible toggle. Turning Protect on removes the exclusion; if no automatic/default/manual evidence remains, direct the user to Add app rather than claim coverage from an empty source set.

For an unavailable excluded ID, offer **Remove exclusion**. Explain that the app becomes covered when Gel discovers it or the user adds it; deleting the exclusion alone cannot supply discovery evidence.

### Remove manual entry

Expose this action in a row's secondary menu when manual evidence exists.

- If discovery/default evidence remains: confirmation says “Remove your saved addition? Gel will still protect <name> through automatic or known-app coverage.”
- If manual evidence is the only source: confirmation says “Remove <name> from Leak Guard? Gel will stop watching this app unless another coverage source includes it.”
- Use **Remove manual entry** / **Cancel**. Preserve any exclusion and avoid deleting or launching an app on disk.

Recheck explicit-policy authority before applying all sheet results. Prevent a state-changing action from using the policy snapshot from when the sheet opened.

## 5. Overlay and explanation copy

Keep the current overlay visual design and actions. Supply the live destination name and frozen trigger summary from the monitor.

- Warn header: “Gel caught a leak · <app>” using the existing component; do not imply a verified transmission elsewhere in explanatory copy.
- Warn summary/action: existing “This would leak: <summary>” and **Paste redacted** / **Ignore**.
- Managed block: existing **Blocked by <organization>**, with the original counts/summary preserved after replacement.
- Unstable action: “Your clipboard changed. Try Paste redacted again.” Do not paste old text.
- Failed replacement: “Couldn't replace the clipboard. Don't paste yet; try again.” Do not show a successful block label.

In Settings help, include: “Warnings happen when copied sensitive text meets a protected app. Gel doesn't intercept every paste. The same copied text can warn once in each app, but counts once while Gel stays open.”

Also disclose: “Restarting Gel can count the same copied text again. Reports name the first app that triggered the incident.” Place this in expandable help rather than repeat it in every overlay.

## 6. Accessibility and focus

- Keep native keyboard navigation for Refresh, Add app, row toggles, disclosures, menus and confirmations. Escape cancels a sheet without mutation.
- Provide toggle labels such as “Protect clipboard in <name>” and expose row state, bundle ID when disambiguation matters, and managed status to VoiceOver.
- Convey Protected/Excluded/Not found through text and control state, not color alone. Disabled managed controls need an accessible reason.
- Retain the monitor's non-activating overlay: app discovery and status publication must not activate Gel or take the browser input focus.
- Preserve existing Reduce Motion behaviour. Opening Settings may focus Gel as a user action; a background refresh must not.
- Long/localized app names and organization names must not push controls outside the card. Test larger accessibility text and a narrow main window.
