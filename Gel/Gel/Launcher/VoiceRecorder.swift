import AVFoundation
import WhisperKit

/// Hold-to-talk recording (16 kHz mono) + on-device transcription with WhisperKit. Audio never leaves the Mac.
@MainActor
final class VoiceRecorder: ObservableObject {
    static let shared = VoiceRecorder()

    enum State: Equatable { case loading, ready, recording, transcribing, unavailable(String) }

    @Published var state: State = .loading
    @Published var level: Float = 0

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
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { _ in }
            return
        case .denied, .restricted:
            state = .unavailable("Microphone access is off. Allow it in System Settings → Privacy → Microphone.")
            return
        default: break
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
        do {
            try engine.start()
            state = .recording
        } catch {
            input.removeTap(onBus: 0)
            state = .unavailable("Couldn't start the microphone.")
        }
    }

    /// Stops recording and returns the transcript (nil if too short or failed).
    func stop() async -> String? {
        guard state == .recording else { return nil }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
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
}
