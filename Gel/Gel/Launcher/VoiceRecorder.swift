import AVFoundation
import GelCore
import WhisperKit

/// Hold-to-talk recording (16 kHz mono) + on-device transcription with WhisperKit. Audio never leaves the Mac.
@MainActor
final class VoiceRecorder: ObservableObject {
    static let shared = VoiceRecorder()

    enum State: Equatable { case loading, ready, recording, transcribing, unavailable(String) }

    @Published var state: State = .loading
    @Published var level: Float = 0
    /// True while Gel has the Mac's sound output muted for this recording (launcher shows "· sound muted").
    @Published var soundMuted = false
    /// Why the last press didn't record, or what to do next (microphone access). Separate from `state`:
    /// access never disables voice, so allowing the microphone works on the next press without a relaunch.
    @Published var micNotice: String?
    var micDenied: Bool { micNotice == MicGate.deniedNotice }
    /// True while the macOS microphone prompt is open. The prompt takes key, so the launcher stays up meanwhile.
    @Published private(set) var askingForAccess = false

    private var whisper: WhisperKit?
    private let engine = AVAudioEngine()
    private var samples: [Float] = []
    private let sampleLock = NSLock()

    /// Preferred model first; a small model if the large one fails to load.
    static let models = ["openai_whisper-large-v3-v20240930_turbo_632MB", "openai_whisper-small"]

    func load() {
        Task {
            for model in Self.models {
                do {
                    let kit = try await WhisperKit(WhisperKitConfig(model: model, verbose: false, prewarm: true, load: true, download: true))
                    whisper = kit
                    state = .ready
                    NSLog("Gel: WhisperKit loaded \(model)")
                    return
                } catch {
                    NSLog("Gel: WhisperKit failed to load \(model): \(error)")
                }
            }
            state = .unavailable("Voice model couldn't load. Typing still works.")
        }
    }

    func start() {
        guard state == .ready else { return }
        switch MicGate.step(for: Self.micAccess()) {
        case .ask:
            askForAccess()
            return
        case .explain(let why):
            micNotice = why
            return
        case .record:
            micNotice = nil
        }
        samples.removeAll()
        let input = engine.inputNode
        let inFormat = input.outputFormat(forBus: 0)
        guard let outFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16_000, channels: 1, interleaved: false),
              let converter = AVAudioConverter(from: inFormat, to: outFormat) else { return }
        input.installTap(onBus: 0, bufferSize: 4096, format: inFormat) { [weak self] buffer, _ in
            guard let self else { return }
            let ratio = outFormat.sampleRate / inFormat.sampleRate
            let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 32
            guard let out = AVAudioPCMBuffer(pcmFormat: outFormat, frameCapacity: capacity) else { return }
            var fed = false
            converter.convert(to: out, error: nil) { _, status in
                if fed { status.pointee = .noDataNow; return nil }
                fed = true
                status.pointee = .haveData
                return buffer
            }
            guard let ch = out.floatChannelData?[0] else { return }
            let chunk = Array(UnsafeBufferPointer(start: ch, count: Int(out.frameLength)))
            let rms = sqrt(chunk.reduce(0) { $0 + $1 * $1 } / Float(max(chunk.count, 1)))
            self.sampleLock.lock(); self.samples += chunk; self.sampleLock.unlock()
            Task { @MainActor in self.level = min(1, rms * 12) }
        }
        if GelSettings.shared.muteWhileTalking { soundMuted = OutputMuter.shared.mute() }
        do {
            try engine.start()
            state = .recording
        } catch {
            input.removeTap(onBus: 0)
            restoreSound()
            state = .unavailable("Couldn't start the microphone.")
        }
    }

    /// Stops recording and returns the transcript (nil if too short or failed).
    func stop() async -> String? {
        guard state == .recording else { return nil }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        restoreSound()
        level = 0
        sampleLock.lock(); let audio = samples; sampleLock.unlock()
        guard audio.count > 16_000 / 3, let whisper else { state = .ready; return nil }
        state = .transcribing
        defer { state = .ready }
        let options = DecodingOptions(task: .transcribe, language: nil, temperature: 0, detectLanguage: true, skipSpecialTokens: true, withoutTimestamps: true)
        let results: [TranscriptionResult] = (try? await whisper.transcribe(audioArray: audio, decodeOptions: options)) ?? []
        let text = results.map(\.text).joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
    }

    /// Stops recording and discards it (the launcher closed mid-recording).
    func cancel() {
        guard state == .recording else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        restoreSound()
        level = 0
        sampleLock.lock(); samples.removeAll(); sampleLock.unlock()
        state = .ready
    }

    /// Re-reads access when the launcher shows: clears a stale denied or prompt notice once access is
    /// granted, and shows the denied notice before the user presses anything.
    func refreshAccess() {
        switch Self.micAccess() {
        case .granted:
            if micNotice == MicGate.deniedNotice || micNotice == MicGate.askingNotice { micNotice = nil }
        case .denied:
            micNotice = MicGate.deniedNotice
        case .undetermined:
            if micNotice == MicGate.deniedNotice { micNotice = nil }
        }
    }

    /// Current microphone access. In DEBUG, `gel.debug.micAccess` (granted|denied|undetermined) replaces it (D-067).
    nonisolated static func micAccess() -> MicGate.Access {
        #if DEBUG
        if let raw = UserDefaults.standard.string(forKey: debugAccessKey), let access = MicGate.Access(rawValue: raw) { return access }
        #endif
        return MicGate.Access(authorizationStatus: AVCaptureDevice.authorizationStatus(for: .audio).rawValue)
    }

    /// Shows the macOS prompt; records nothing this press. The answer arrives off the main thread.
    private func askForAccess() {
        micNotice = MicGate.askingNotice
        guard !askingForAccess else { return }
        askingForAccess = true
        let answered: @Sendable (Bool) -> Void = { granted in
            Task { @MainActor [weak self] in
                self?.micNotice = MicGate.notice(afterAnswer: granted)
                self?.askingForAccess = false
            }
        }
        #if DEBUG
        if UserDefaults.standard.string(forKey: Self.debugAccessKey) == MicGate.Access.undetermined.rawValue {
            // Simulated prompt: `gel.debug.micRequest` (granted|denied, default granted) answers after 0.5 s,
            // and becomes the override's value, as a real answer changes the real status.
            let granted = UserDefaults.standard.string(forKey: "gel.debug.micRequest") != "denied"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                UserDefaults.standard.set(granted ? "granted" : "denied", forKey: Self.debugAccessKey)
                answered(granted)
            }
            return
        }
        #endif
        AVCaptureDevice.requestAccess(for: .audio, completionHandler: answered)
    }

    #if DEBUG
    private nonisolated static let debugAccessKey = "gel.debug.micAccess"
    #endif

    private func restoreSound() {
        OutputMuter.shared.restore()
        soundMuted = false
    }
}
