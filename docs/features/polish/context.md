# U9 · Polish & motion — Context

## Why it exists

Every module works, but the app reads as "SwiftUI defaults on a warm palette": no app icon (the Dock shows the generic one), an SF Symbol drop as the logo, instant module switches, a launcher that only fades, a leak overlay that pops in with no sense of urgency, numbers that change silently. Judges see the app for five minutes on a projector; the first impression and the moments in the demo script (launcher answer, citation → page, leak caught, stats tick up) carry the score for polish.

## Where it sits

Cross-cutting UI layer over U1–U6. Touches only the `Gel` app target: `App/Theme.swift` (tokens, motion, shared components), new `App/Brand.swift` (mark + icon drawing), new `Gel/Assets.xcassets`, and the views of each module. `GelCore` is not touched.

## Current state (before this pass)

- `Theme` has colours only; no motion or typography tokens. Components: `Card`, `ProviderBadge`, `CitationChip`, `StatCard`, `LockedLabel`, `EmptyStateView`, `FlowLayout`, `ModuleHeader`.
- Animations today: launcher panel fade (150/100 ms), answer `.easeOut` on every token, `LevelMeter`, a shimmer whose highlight is a solid-colour overlay (reads as a moving grey bar in dark mode).
- No asset catalog, no `AppIcon` (app-shell T6 open). Menu bar uses SF Symbol `drop`.
- `PDFView` background is a hard-coded light beige even in dark mode.
- `.borderedProminent.tint(accent)` buttons turn grey when the window isn't key, so CTAs lose the brand colour in screenshots.

## Facts and gotchas

- The launcher is an `NSPanel` resized by `LauncherController.fitToContent()` on every model change (16 ms debounce). Animating SwiftUI height *and* the panel frame fights; resize the panel only, keep top edge fixed.
- Streaming appends a token per callback; animating the whole `Text` on each token causes reflow shimmer. Animate the container height, not the text.
- `NavigationSplitView` sidebar background is overridden with `Theme.canvas`; `matchedGeometryEffect` works inside it.
- XcodeGen picks up `Gel/Assets.xcassets` from the `Gel` source path; the app icon name must be set with `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon` in `project.yml`.
- Leak overlay lives in a separate `.statusBar`-level `NSPanel`; its slide must be done on the panel frame (AppKit) or inside the hosting view with a clear margin.

## Related docs

[spec](spec.md) · [design](design.md) · [tasks](tasks.md) · [app-shell design](../app-shell/design.md) · [launcher design](../launcher/design.md)
