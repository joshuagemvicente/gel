# U2 · Launcher — Context

## Why it exists

The launcher is the first thing judges see: demo step 1 is ⌥Space, a spoken Taglish question, and a streamed answer with citation chips and a **Local** badge, with Wi-Fi off ([demo script](../../project/demo-and-submission.md)). It proves the local-AI claim (**Local AI Implementation, 25%**) and sets the polish bar (**Product & Demo Quality, 15%**).

## Where it sits

- **Upstream:** app-shell (`AppState`, main window control), query-citations (`QueryEngine.ask`), voice (transcript into the field), model-fallback (provider badge).
- **Downstream:** library-viewer (chip → page highlight), history ("Open in Gel").

## Current state

- Nothing built in the app target.
- Engine ready: `QueryEngine.shared.ask(_ question:, onToken:) async throws -> AnswerResult` streams tokens and returns citations, provider, model and `sentPayload`.
- KeyboardShortcuts package is declared in `project.yml`.

## Facts and gotchas

- **Panel focus:** use an `NSPanel` subclass with `.nonactivatingPanel` + `.borderless`, `canBecomeKey = true`, level `.floating`, `collectionBehavior` `[.canJoinAllSpaces, .fullScreenAuxiliary]`, so it appears over full-screen apps and accepts typing without bringing the main window forward.
- **Close on outside click:** observe `NSWindow.didResignKeyNotification` and close.
- **Streaming on the main actor:** `onToken` runs off the main thread; append to the published answer via `MainActor`/`DispatchQueue.main`.
- **Timing:** with the model warm, first token is a few seconds (qwen3 4B instruct at ~24 tok/s; real numbers get recorded in [decisions](../../project/decisions.md)). Show a shimmer until then.
- **Hotkey conflict:** the ChatGPT desktop app also binds ⌥Space; Gel keeps it and the demo uses chatgpt.com in Chrome (D-019).
- **Demo question:** "Sino sa applicants ang may 5+ years sa payroll?" → Reyes, Santos, Cruz.

## Related docs

[spec](spec.md) · [design](design.md) · [tasks](tasks.md) · [query-citations](../query-citations/spec.md) · [voice](../voice/spec.md)
