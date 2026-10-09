# F2 · Voice input — Tasks

Legend: `[x]` done and verified · `[~]` built, not verified · `[ ]` not started.

- [x] **T1 Resolve WhisperKit and confirm its API.** Build the `Gel` scheme once so the package resolves; read `WhisperKit.swift` / `WhisperKitConfig` and the `transcribe(audioArray:)` signature in the checkout. Files: none (record findings in [interfaces](interfaces.md) if they differ). **Verify:** `xcodebuild -project Gel.xcodeproj -scheme Gel -derivedDataPath build -quiet build` succeeds.
- [~] **T2 `Transcriber`.** Load `large-v3-v20240930_turbo` in the background at launch, fall back to `small`; expose `state` (loading/ready/failed(reason)) and `transcribe(_ samples: [Float]) async throws -> String`. Files: `Gel/Voice/Transcriber.swift`. **Verify:** a debug menu item or test harness transcribes a short recorded clip; log shows model ready.
- [~] **T3 `VoiceRecorder`.** AVAudioEngine capture → 16 kHz mono Float32 buffer; publish a 0–1 level for the meter; start/stop. Files: `Gel/Voice/VoiceRecorder.swift`. **Verify:** level meter moves while speaking; stopping returns ~16,000 samples per second recorded.
- [~] **T4 Hold-right-⌥ in the launcher.** Local `.flagsChanged` monitor (keyCode 61) while the launcher is key; press = start, release = stop → transcribe → fill field → run. Mic button press-and-hold does the same. Files: launcher views. **Verify:** hold, say a Taglish question, release → text appears and the answer starts.
- [~] **T5 Failure paths.** Mic denied or model failed → mic glyph disabled with a one-line reason; typing unaffected. **Verify:** deny mic in System Settings → launcher explains and typed questions still work.
- [ ] **T6 Measure.** Time release→text for 3 phrases with Wi-Fi off; record in [decisions](../../project/decisions.md).

Done when: all [spec.md](spec.md) acceptance criteria observed passing.
