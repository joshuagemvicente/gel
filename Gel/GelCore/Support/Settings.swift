import Foundation
import Security

public enum GelPaths {
    /// Application Support/Gel, or $GEL_HOME when set (used by gelcli and tests).
    public static var home: URL {
        let url: URL
        if let override = ProcessInfo.processInfo.environment["GEL_HOME"], !override.isEmpty {
            url = URL(fileURLWithPath: override, isDirectory: true)
        } else {
            url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("Gel", isDirectory: true)
        }
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    public static var database: URL { home.appendingPathComponent("index.sqlite") }
    public static var policy: URL { home.appendingPathComponent("policy.json") }
    public static var reports: URL {
        let url = home.appendingPathComponent("Reports", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}

/// User-facing settings. Non-secret values live in UserDefaults; the cloud API key lives in the Keychain.
public final class GelSettings {
    public static let shared = GelSettings()
    private let defaults: UserDefaults
    private let env: [String: String]

    public init(defaults: UserDefaults = UserDefaults(suiteName: "com.joshuagemvicente.gel") ?? .standard,
                env: [String: String] = ProcessInfo.processInfo.environment) {
        self.defaults = defaults
        self.env = env
    }

    public static let defaultLocalModel = "qwen3:4b-instruct-2507-q4_K_M"
    public static let defaultEmbedModel = "bge-m3"

    /// The folders Gel reads. `GEL_FOLDER` (paths separated by ":") overrides the stored list. Before U10 a single
    /// `folderPath` was stored; it becomes the first entry until the list is saved.
    public var folderPaths: [String] {
        get {
            if folderPathsFromEnvironment, let e = env["GEL_FOLDER"] {
                return e.split(separator: ":").map { FolderList.standardize(String($0)) }
            }
            if let list = defaults.stringArray(forKey: "folderPaths") { return list }
            return defaults.string(forKey: "folderPath").map { [FolderList.standardize($0)] } ?? []
        }
        set { defaults.set(newValue, forKey: "folderPaths") }
    }

    public var folderPathsFromEnvironment: Bool { !(env["GEL_FOLDER"] ?? "").isEmpty }

    public var localBaseURL: String {
        get { defaults.string(forKey: "localBaseURL") ?? "http://localhost:11434" }
        set { defaults.set(newValue, forKey: "localBaseURL") }
    }

    public var localModel: String {
        get { env["GEL_LOCAL_MODEL"] ?? defaults.string(forKey: "localModel") ?? Self.defaultLocalModel }
        set { defaults.set(newValue, forKey: "localModel") }
    }

    /// `GEL_LOCAL_MODEL` pins the chat model; Settings locks the presets while it's set.
    public var localModelFromEnvironment: Bool { !(env["GEL_LOCAL_MODEL"] ?? "").isEmpty }

    public var embedModel: String {
        get { defaults.string(forKey: "embedModel") ?? Self.defaultEmbedModel }
        set { defaults.set(newValue, forKey: "embedModel") }
    }

    public var cloudEnabled: Bool {
        get { env["GEL_CLOUD_BASE_URL"] != nil || defaults.bool(forKey: "cloudEnabled") }
        set { defaults.set(newValue, forKey: "cloudEnabled") }
    }

    public var cloudBaseURL: String {
        get { env["GEL_CLOUD_BASE_URL"] ?? defaults.string(forKey: "cloudBaseURL") ?? "" }
        set { defaults.set(newValue, forKey: "cloudBaseURL") }
    }

    public var cloudModel: String {
        get { env["GEL_CLOUD_MODEL"] ?? defaults.string(forKey: "cloudModel") ?? "" }
        set { defaults.set(newValue, forKey: "cloudModel") }
    }

    public var cloudAPIKey: String {
        get { env["GEL_CLOUD_API_KEY"] ?? Keychain.read(account: "cloudAPIKey") ?? "" }
        set { Keychain.write(account: "cloudAPIKey", value: newValue) }
    }

    public var firstTokenTimeout: TimeInterval {
        get { let v = defaults.double(forKey: "firstTokenTimeout"); return v > 0 ? v : 15 }
        set { defaults.set(newValue, forKey: "firstTokenTimeout") }
    }

    public var totalTimeout: TimeInterval {
        get { let v = defaults.double(forKey: "totalTimeout"); return v > 0 ? v : 30 }
        set { defaults.set(newValue, forKey: "totalTimeout") }
    }

    public var activePacks: [String] {
        get { defaults.stringArray(forKey: "activePacks") ?? ["hr"] }
        set { defaults.set(newValue, forKey: "activePacks") }
    }

    /// Leak Guard's safe paste (⌥⌘V) and block mode put dummy data on the clipboard instead of placeholders (R5).
    /// Off by default.
    public var leakGuardPasteDummy: Bool {
        get { defaults.bool(forKey: "leakGuardPasteDummy") }
        set { defaults.set(newValue, forKey: "leakGuardPasteDummy") }
    }

    /// Mute the Mac's sound output while hold-to-talk records (voice spec addendum). On by default.
    public var muteWhileTalking: Bool {
        get { defaults.object(forKey: "muteWhileTalking") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "muteWhileTalking") }
    }

    public var onboardingDone: Bool {
        get { defaults.bool(forKey: "onboardingDone") }
        set { defaults.set(newValue, forKey: "onboardingDone") }
    }

    public var cloudConfig: CloudConfig? {
        guard cloudEnabled, !cloudBaseURL.isEmpty, !cloudModel.isEmpty else { return nil }
        return CloudConfig(baseURL: cloudBaseURL, apiKey: cloudAPIKey, model: cloudModel)
    }
}

public struct CloudConfig: Equatable {
    public var baseURL: String
    public var apiKey: String
    public var model: String
    public init(baseURL: String, apiKey: String, model: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.model = model
    }
}

enum Keychain {
    private static let service = "com.joshuagemvicente.gel"

    static func read(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func write(account: String, value: String) {
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(base as CFDictionary)
        guard !value.isEmpty else { return }
        var add = base
        add[kSecValueData as String] = Data(value.utf8)
        SecItemAdd(add as CFDictionary, nil)
    }
}
