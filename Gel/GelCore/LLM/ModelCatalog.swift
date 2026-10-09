import Foundation

/// A recommended local chat model shown in Settings › Models (U11).
public struct ModelPreset: Identifiable, Equatable, Sendable {
    public enum Tier: String, Sendable { case light, balanced, quality }

    /// The Ollama tag, e.g. `qwen3:4b-instruct-2507-q4_K_M`.
    public let id: String
    public let tier: Tier
    public let name: String
    /// Download size from the Ollama registry (sum of the manifest's layers).
    public let downloadBytes: Int64
    public let recommendedRAMGB: Int
    /// Median of the demo question on the M2 16 GB, warm model (U11 T1, logged in decisions.md). Nil = not measured.
    public let firstWordsSeconds: Double?
    public let totalSeconds: Double?

    public var tag: String { id }
}

public enum ModelCatalog {
    /// Only presets that answered the demo question correctly with citations on the M2 ship (U11 T1, D-065):
    /// llama3.2:3b, gemma3:4b, gemma3:12b and qwen2.5:7b were measured and dropped.
    public static let presets: [ModelPreset] = [
        ModelPreset(id: GelSettings.defaultLocalModel, tier: .balanced, name: "Qwen3 4B Instruct",
                    downloadBytes: 2_500_000_000, recommendedRAMGB: 8, firstWordsSeconds: 12.4, totalSeconds: 16.9),
    ]

    /// The embedding model is fixed (changing it would force a full re-index) and pulled with the first chat model.
    public static let embeddingTag = GelSettings.defaultEmbedModel
    public static let embeddingBytes: Int64 = 1_160_000_000

    /// Free space Gel keeps on top of a download.
    public static let diskMargin: Int64 = 1_000_000_000

    public static func preset(for tag: String) -> ModelPreset? {
        presets.first { $0.id == tag || $0.id + ":latest" == tag }
    }

    /// Installed RAM in whole GB (a 16 GB Mac reports exactly 16).
    public static var physicalMemoryGB: Int {
        Int((Double(ProcessInfo.processInfo.physicalMemory) / 1_073_741_824).rounded())
    }

    /// True when this Mac has less RAM than the preset recommends (shown as a warning, never a block).
    public static func lacksRAM(_ preset: ModelPreset, memoryGB: Int = physicalMemoryGB) -> Bool {
        memoryGB < preset.recommendedRAMGB
    }

    /// Free space on the volume holding the home folder (Ollama keeps models in ~/.ollama).
    public static func freeDiskBytes() -> Int64? {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let values = try? home.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        return values?.volumeAvailableCapacityForImportantUsage
    }

    /// True when `needed` bytes plus the margin don't fit in `free`.
    public static func lacksDisk(needed: Int64, free: Int64) -> Bool {
        needed + diskMargin > free
    }

    /// Whether an installed-model list (names from `/api/tags`) contains `tag`.
    public static func isInstalled(_ tag: String, in installed: [String]) -> Bool {
        installed.contains(tag) || installed.contains(tag + ":latest")
    }
}
