# F2 · Voice input — Tasks

Legend: `[x]` done and verified · `[~]` built, not verified · `[ ]` not started.

- [x] **T1 Resolve WhisperKit and confirm its API.** Build the `Gel` scheme once so the package resolves; read `WhisperKit.swift` / `WhisperKitConfig` and the `transcribe(audioArray:)` signature in the checkout. Files: none (record findings in [interfaces](interfaces.md) if they differ). **Verify:** `xcodebuild -project Gel.xcodeproj -scheme Gel -derivedDataPath build -quiet build` succeeds.
- [~] **T2 `Transcriber`.** Load `large-v3-v20240930_turbo` in the background at launch, fall back to `small`; expose `state` (loading/ready/failed(reason)) and `transcribe(_ samples: [Float]) async throws -> String`. Files: `Gel/Voice/Transcriber.swift`. **Verify:** a debug menu item or test harness transcribes a short recorded clip; log shows model ready.
- [~] **T3 `VoiceRecorder`.** AVAudioEngine capture → 16 kHz mono Float32 buffer; publish a 0–1 level for the meter; start/stop. Files: `Gel/Voice/VoiceRecorder.swift`. **Verify:** level meter moves while speaking; stopping returns ~16,000 samples per second recorded.
- [~] **T4 Hold-right-⌥ in the launcher.** Local `.flagsChanged` monitor (keyCode 61) while the launcher is key; press = start, release = stop → transcribe → fill field → run. Mic button press-and-hold does the same. Files: launcher views. **Verify:** hold, say a Taglish question, release → text appears and the answer starts.
- [~] **T5 Failure paths.** Mic denied or model failed → mic glyph disabled with a one-line reason; typing unaffected. **Verify:** deny mic in System Settings → launcher explains and typed questions still work.
- [ ] **T6 Measure.** Time release→text for 3 phrases with Wi-Fi off; record in [decisions](../../project/decisions.md).

- [x] **T7 `OutputMuter`.** Core Audio: default output device → mute property, or virtual main volume as a fallback; record what was changed (device UID, kind, previous volume) in UserDefaults before changing it; `mute()` / `restore()` that only undo Gel's own change. The device access sits behind a small protocol so the logic can be tested against a fake. Files: `Gel/GelCore/Support/OutputMuter.swift` (in GelCore so it can be unit-tested), `Gel/GelCoreTests/OutputMuterTests.swift`. **Verify:** unit tests for M2, M3, M7 logic; `xcodebuild` build.
- [x] **T8 Wire into recording.** `VoiceRecorder.start()` mutes after permission checks and right before `engine.start()` (restores on failure); `stop()` restores right after `engine.stop()`; a new `cancel()` stops and discards. The launcher cancels when it hides mid-recording. `AppDelegate` restores at launch and on terminate. Launcher cue "· sound muted". DEBUG `gel.debug.holdToTalk` hook (down/up) so the flow can be driven without a physical key. Files: `VoiceRecorder.swift`, `LauncherController.swift`, `LauncherView.swift`, `AppDelegate.swift`. **Verify:** M1, M4, M5, M8 via the hook and reading the device's mute state.
- [~] **T9 Setting.** `GelSettings.muteWhileTalking` (default true); Settings → Hotkeys toggle. Files: `Settings.swift`, `SettingsView.swift`. **Verify:** M6.

Done when: all [spec.md](spec.md) acceptance criteria observed passing.

## Mute-while-talking verification log (2026-10-10, 01:50–02:00)

- **Tests:** 31/31 `GelCoreTests` pass, including 7 in `OutputMuterTests`:
  - mute and restore
  - already muted (M2)
  - user change kept (M3)
  - volume fallback with the exact previous value (M7)
  - device with no controls
  - restore after the default device switched
  - a crash record restored by a fresh muter (M5)
- **Live:** Debug build with a scratch `GEL_HOME`, driven by `gel.debug.holdToTalk` (D-059). The output state was read from Core Audio (MacBook Air Speakers). The speakers were set to volume 0 first so nothing was audible, and were afterwards restored to the user's state (muted, 0.4375).
  - **M1:** muted about 0.2 s after recording started; unmuted on release; no saved record left behind.
  - **M8:** launcher read "Listening… release ⌥ to ask · sound muted" (screenshot).
  - **M4:** switched to Finder mid-recording → launcher hid, output unmuted, record cleared.
  - **M2:** muted beforehand → still muted after; the launcher showed no "· sound muted".
  - **M6:** `muteWhileTalking` false → recording ran ("Listening…") and the output stayed unmuted.
  - **M5:** Quit mid-recording → Gel quit, output unmuted. Kill -9 mid-recording → output stayed muted with record `BuiltInSpeakerDevice`/mute, and the next launch restored it and cleared the record.
- **Not observed:**
  - the Settings toggle on screen (the `gel.debug.module settings` hook didn't switch screens)
  - M7 on real hardware (no output without a mute switch at hand)
  - M9, speaking with music playing (user)

## Microphone permission recovery (Oct 10)

- [x] **T10 `MicGate`.** GelCore: `enum Access { granted, undetermined, denied }`; `step(for:)` → `.record`, `.ask`, `.explain(String)`; `notice(afterAnswer granted: Bool) -> String`; copy strings as constants. Files: `Gel/GelCore/Support/MicGate.swift`, `Gel/GelCoreTests/MicGateTests.swift`. **Verify:** P1.
- [~] **T11 `VoiceRecorder` access handling.** Remove the `.unavailable` writes for access; add `@Published var micNotice: String?`; `start()` asks `MicGate` each press; the `requestAccess` answer sets the notice on the main actor; `refreshAccess()` clears a stale denied notice; DEBUG `gel.debug.micAccess` / `gel.debug.micRequest` override; publish `askingForAccess` while the prompt is open. Files: `VoiceRecorder.swift`. **Verify:** P2, P3; P8 manually (real prompt, not the DEBUG simulation).
- [~] **T12 Launcher.** `prepareForShow()` calls `voice.refreshAccess()`; the mic tooltip, VoiceOver label and idle row show `micNotice` (a model failure first, in both); the glyph is dimmed while denied; `windowDidResignKey` doesn't hide while `askingForAccess`, and the panel takes key back when the prompt is answered (D-068). Files: `LauncherController.swift`, `LauncherView.swift`. **Verify:** P2, P4; P7 and P8 manually (user, real permission; no `tccutil`, no privacy changes by the agent).
- [~] **T13 Settings live refresh.** Re-read both permission rows on `NSApplication.didBecomeActiveNotification`. Files: `SettingsView.swift`. **Verify:** P5.
- [x] **T14 Release check + decisions.** Release build compiles; log the DEBUG override in `docs/project/decisions.md`. **Verify:** P6.

## Microphone permission recovery verification log (2026-10-10, 03:51–03:57)

- **Tests and builds:** 47/47 `GelCoreTests` pass, including `MicGateTests` (P1). Debug and Release builds succeed; the overrides sit behind `#if DEBUG` (P6).
- **Live:** Debug build with a scratch `GEL_HOME`, voice model loaded (large-v3 turbo). Driven only by `gel.debug.micAccess` / `gel.debug.micRequest` (D-067) and the `gel.debug.holdToTalk` / `gel.debug.ask` hooks (D-059, D-038). The Mac's privacy settings were not changed. Screenshots read for each step.
  - **P2:** `denied` → press → idle row read "Microphone access is off. Allow it in System Settings → Privacy → Microphone.", glyph dimmed, no "Listening…". Switched to `granted`, closed the launcher (Finder took focus) and reopened it → notice gone, "right ⌥ hold to talk" hint back. Next press → "Listening… release ⌥ to ask"; the real mic recorded and the release transcribed and ran.
  - **P3, Allow:** `undetermined` + `micRequest granted`, fresh launch → press → "Allow the microphone in the macOS prompt.", no recording → 0.5 s later "Microphone on. Hold right ⌥ again to talk."; override written back as `granted`. Next press → "Listening…".
  - **P3, Don't Allow:** `undetermined` + `micRequest denied` → prompt notice, then the denied notice; override written back as `denied`.
  - **P4:** while `denied`, `gel.debug.ask` "What is the refund policy?" → launcher answered ("I couldn't find that in your files.", Local · Qwen3 4B). The idle row showed the denied notice in place of the key hint (P2 and P3 frames).
- **Not observed:**
  - **P5:** `gel.debug.module settings` opened Settings, but the switch-away-and-back check wasn't read. Opening Settings reads the cloud API key, and macOS showed a keychain password prompt for the rebuilt Debug binary over the window. The Permissions card is also below the fold, and the accessibility dump came back empty. Left for a manual check.
  - The mic glyph's tooltip and VoiceOver label (only the idle row was read).
  - **P7, P8:** manual (user, real permission and real first prompt).
- **Side effects:** while the user was typing in another app, the launcher held key focus for a few seconds and caught some of their keystrokes ("ommit" in the field). Overrides deleted, scratch `GEL_HOME` removed, and the Debug app relaunched with the default home, as it was running before.
