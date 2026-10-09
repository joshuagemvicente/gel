import Foundation
import CoreAudio
import AudioToolbox

/// A sound output Gel can silence: its own mute switch, or its volume when it has none.
public protocol OutputDevice {
    var uid: String { get }
    var canMute: Bool { get }
    var isMuted: Bool { get nonmutating set }
    var canSetVolume: Bool { get }
    var volume: Float { get nonmutating set }
}

/// Finds output devices: the current default, or one by UID (to restore the device Gel muted after the default changed).
public protocol OutputDeviceSource {
    func defaultOutput() -> OutputDevice?
    func device(uid: String) -> OutputDevice?
}

/// Mutes the Mac's sound output while the user talks and undoes only its own change (voice spec addendum).
/// What it changed is saved before changing it, so a crash mid-recording is undone at the next launch.
public final class OutputMuter {
    public static let shared = OutputMuter()

    /// What Gel changed, persisted as a dictionary under `recordKey`.
    struct Record: Equatable {
        enum Kind: String { case mute, volume }
        var uid: String
        var kind: Kind
        var previousVolume: Float
    }

    static let recordKey = "outputMuteRecord"
    private let source: OutputDeviceSource
    private let defaults: UserDefaults

    public init(source: OutputDeviceSource = CoreAudioOutputs(),
                defaults: UserDefaults = UserDefaults(suiteName: "com.joshuagemvicente.gel") ?? .standard) {
        self.source = source
        self.defaults = defaults
    }

    /// True while Gel has an output muted (drives the launcher's "· sound muted").
    public var isActive: Bool { record != nil }

    var record: Record? {
        get {
            guard let d = defaults.dictionary(forKey: Self.recordKey), let uid = d["uid"] as? String,
                  let kind = (d["kind"] as? String).flatMap(Record.Kind.init) else { return nil }
            return Record(uid: uid, kind: kind, previousVolume: (d["previousVolume"] as? NSNumber)?.floatValue ?? 0)
        }
        set {
            guard let r = newValue else { defaults.removeObject(forKey: Self.recordKey); return }
            defaults.set(["uid": r.uid, "kind": r.kind.rawValue, "previousVolume": r.previousVolume], forKey: Self.recordKey)
        }
    }

    /// Silences the default output. Does nothing if it is already silent or can't be changed. Returns whether it muted.
    @discardableResult
    public func mute() -> Bool {
        if record != nil { restore() }
        guard let device = source.defaultOutput() else { return false }
        if device.canMute {
            guard !device.isMuted else { return false }
            record = Record(uid: device.uid, kind: .mute, previousVolume: 0)
            device.isMuted = true
            return true
        }
        if device.canSetVolume {
            let previous = device.volume
            guard previous > 0 else { return false }
            record = Record(uid: device.uid, kind: .volume, previousVolume: previous)
            device.volume = 0
            return true
        }
        return false
    }

    /// Undoes Gel's change, unless the user changed that device's mute or volume since.
    public func restore() {
        guard let r = record else { return }
        record = nil
        guard let device = source.device(uid: r.uid) else { return }
        switch r.kind {
        case .mute: if device.isMuted { device.isMuted = false }
        case .volume: if device.volume == 0 { device.volume = r.previousVolume }
        }
    }
}

// MARK: - Core Audio

public struct CoreAudioOutputs: OutputDeviceSource {
    public init() {}

    public func defaultOutput() -> OutputDevice? {
        var id = AudioObjectID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice,
                                                 mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &id) == noErr,
              id != kAudioObjectUnknown else { return nil }
        return CoreAudioOutput(id: id)
    }

    public func device(uid: String) -> OutputDevice? {
        var ids = [AudioObjectID]()
        var size: UInt32 = 0
        var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices,
                                                 mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        let system = AudioObjectID(kAudioObjectSystemObject)
        guard AudioObjectGetPropertyDataSize(system, &address, 0, nil, &size) == noErr else { return nil }
        ids = Array(repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
        guard AudioObjectGetPropertyData(system, &address, 0, nil, &size, &ids) == noErr else { return nil }
        return ids.map(CoreAudioOutput.init).first { $0.uid == uid }
    }
}

struct CoreAudioOutput: OutputDevice {
    let id: AudioObjectID

    private static func address(_ selector: AudioObjectPropertySelector) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: selector, mScope: kAudioDevicePropertyScopeOutput, mElement: kAudioObjectPropertyElementMain)
    }

    var uid: String {
        var address = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyDeviceUID,
                                                 mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        var uid: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        guard AudioObjectGetPropertyData(id, &address, 0, nil, &size, &uid) == noErr, let uid else { return "" }
        return uid.takeRetainedValue() as String
    }

    private func settable(_ selector: AudioObjectPropertySelector) -> Bool {
        var address = Self.address(selector)
        var settable: DarwinBoolean = false
        return AudioObjectHasProperty(id, &address)
            && AudioObjectIsPropertySettable(id, &address, &settable) == noErr && settable.boolValue
    }

    var canMute: Bool { settable(kAudioDevicePropertyMute) }

    var isMuted: Bool {
        get {
            var address = Self.address(kAudioDevicePropertyMute)
            var value: UInt32 = 0
            var size = UInt32(MemoryLayout<UInt32>.size)
            return AudioObjectGetPropertyData(id, &address, 0, nil, &size, &value) == noErr && value != 0
        }
        nonmutating set {
            var address = Self.address(kAudioDevicePropertyMute)
            var value: UInt32 = newValue ? 1 : 0
            AudioObjectSetPropertyData(id, &address, 0, nil, UInt32(MemoryLayout<UInt32>.size), &value)
        }
    }

    var canSetVolume: Bool {
        var address = Self.address(kAudioHardwareServiceDeviceProperty_VirtualMainVolume)
        var settable: DarwinBoolean = false
        return AudioHardwareServiceHasProperty(id, &address)
            && AudioHardwareServiceIsPropertySettable(id, &address, &settable) == noErr && settable.boolValue
    }

    var volume: Float {
        get {
            var address = Self.address(kAudioHardwareServiceDeviceProperty_VirtualMainVolume)
            var value: Float32 = 0
            var size = UInt32(MemoryLayout<Float32>.size)
            return AudioHardwareServiceGetPropertyData(id, &address, 0, nil, &size, &value) == noErr ? value : 0
        }
        nonmutating set {
            var address = Self.address(kAudioHardwareServiceDeviceProperty_VirtualMainVolume)
            var value = Float32(newValue)
            AudioHardwareServiceSetPropertyData(id, &address, 0, nil, UInt32(MemoryLayout<Float32>.size), &value)
        }
    }
}
