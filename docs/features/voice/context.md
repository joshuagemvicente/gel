# F2 · Voice input — Context

## Why it exists

The opening demo beat is spoken, offline: *"Sino sa applicants ang may 5+ years sa payroll?"* with Wi-Fi off. Voice is the "unusual way to use it" the user chose, and on-device speech is a visible part of the **Local AI implementation** score ([context](../../project/context.md), [demo](../../project/demo-and-submission.md)).

## Where it sits

- **Upstream:** microphone permission; WhisperKit model files (downloaded once at first load).
- **Downstream:** [launcher](../launcher/spec.md) (fills the field, runs the question) → [query-citations](../query-citations/spec.md).
- **Owner of the load at launch:** [app-shell](../app-shell/spec.md).

## Current state

Not built. Declared only:

- `Gel/project.yml`: package `WhisperKit` (`https://github.com/argmaxinc/WhisperKit`, `from: 0.9.0`) linked to the `Gel` app target.
- `Gel/Info.plist` (generated): `NSMicrophoneUsageDescription` = "Gel transcribes your voice questions on this Mac. Audio never leaves your device."
- `Gel/Gel.entitlements`: `com.apple.security.device.audio-input` = true, no sandbox.

The package has not been resolved/built yet in this session (only `gelcli` was built), so the exact API is unconfirmed.

## Facts and gotchas

- Whisper expects **16 kHz mono Float32**; AVAudioEngine's input node is usually 44.1/48 kHz, so convert with `AVAudioConverter`.
- Model choice: `large-v3-v20240930_turbo` (~1.6 GB, best Taglish), fallback `small`. First load downloads from Hugging Face (needs internet once; do it before Demo Day).
- Memory budget on 16 GB: WhisperKit + Qwen3 4B + bge-m3 ≈ 6–7 GB total ([context](../../project/context.md)).
- Right ⌥ detection: `NSEvent` `.flagsChanged` with keyCode 61 (right Option). A **local** monitor works while the launcher is key; no Input Monitoring permission needed.
- macOS asks for microphone permission on first `AVAudioEngine.start()`; the prompt text comes from Info.plist.

## Related

[spec](spec.md) · [tasks](tasks.md) · [interfaces](interfaces.md) · [launcher](../launcher/spec.md)
