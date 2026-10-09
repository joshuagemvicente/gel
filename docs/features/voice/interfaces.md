# F2 · Voice input — Interfaces

Voice lives in the **app target** (`Gel/Voice/`), not `GelCore`, because it depends on WhisperKit and AVFoundation. Everything below is **to build**.

## To build

```swift
/// Owns the WhisperKit pipeline. Created once by AppState at launch.
@MainActor final class Transcriber: ObservableObject {
    enum State: Equatable { case idle, loading, ready, failed(String) }
    @Published private(set) var state: State
    func load() async                                   // large-v3-v20240930_turbo, then "small" on failure
    func transcribe(_ samples: [Float]) async throws -> String   // 16 kHz mono Float32; trimmed text
}

/// Microphone capture for push-to-talk.
@MainActor final class VoiceRecorder: ObservableObject {
    @Published private(set) var isRecording: Bool
    @Published private(set) var level: Float            // 0…1, for the launcher's meter
    func start() throws                                  // requests mic permission on first use
    func stop() -> [Float]                               // 16 kHz mono Float32 samples
}
```

WhisperKit calls (confirm against the resolved source, task T1): `WhisperKit(WhisperKitConfig(model:))` to load, `transcribe(audioArray:)` returning results whose `.text` values are joined.

## Consumed

- [launcher](../launcher/spec.md): owns the hold-to-talk gesture; after `stop()` + `transcribe`, sets the field text and calls `QueryEngine.shared.ask(_:onToken:)` ([query-citations interfaces](../query-citations/interfaces.md)).
- [app-shell](../app-shell/spec.md): calls `Transcriber.load()` in the launch sequence; exposes `state` to Settings → Permissions/Models.

## Invariants

- Audio stays in memory and is discarded after transcription; it is never written to disk or the database.
- No network call besides WhisperKit's one-time model download.
