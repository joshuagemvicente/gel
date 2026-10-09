import XCTest
@testable import GelCore

final class OutputMuterTests: XCTestCase {
    final class FakeDevice: OutputDevice {
        let uid: String
        let canMute: Bool
        let canSetVolume: Bool
        var isMuted = false
        var volume: Float = 0.6
        init(uid: String, canMute: Bool = true, canSetVolume: Bool = true) {
            self.uid = uid; self.canMute = canMute; self.canSetVolume = canSetVolume
        }
    }

    struct FakeSource: OutputDeviceSource {
        var current: () -> FakeDevice?
        var all: [FakeDevice]
        func defaultOutput() -> OutputDevice? { current() }
        func device(uid: String) -> OutputDevice? { all.first { $0.uid == uid } }
    }

    private var suite = ""
    private var defaults: UserDefaults!

    override func setUp() {
        suite = "gel.tests.muter.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)
    }

    override func tearDown() { defaults.removePersistentDomain(forName: suite) }

    private func muter(_ devices: [FakeDevice], current: FakeDevice? = nil) -> OutputMuter {
        let cur = current ?? devices.first
        return OutputMuter(source: FakeSource(current: { cur }, all: devices), defaults: defaults)
    }

    func testMutesAndRestores() {
        let speakers = FakeDevice(uid: "speakers")
        let m = muter([speakers])
        XCTAssertTrue(m.mute())
        XCTAssertTrue(speakers.isMuted)
        XCTAssertTrue(m.isActive)
        m.restore()
        XCTAssertFalse(speakers.isMuted)
        XCTAssertFalse(m.isActive)
    }

    /// M2: already muted stays muted.
    func testAlreadyMutedIsLeftAlone() {
        let speakers = FakeDevice(uid: "speakers")
        speakers.isMuted = true
        let m = muter([speakers])
        XCTAssertFalse(m.mute())
        m.restore()
        XCTAssertTrue(speakers.isMuted)
    }

    /// M3: a change the user made mid-recording wins.
    func testUserChangeDuringRecordingIsKept() {
        let speakers = FakeDevice(uid: "speakers")
        let m = muter([speakers])
        m.mute()
        speakers.isMuted = false          // user unmutes by hand
        m.restore()
        XCTAssertFalse(speakers.isMuted)
        m.mute()
        m.restore()
        XCTAssertFalse(speakers.isMuted)
    }

    /// M7: a device without a mute switch gets volume 0, then its exact previous volume.
    func testVolumeFallback() {
        let hdmi = FakeDevice(uid: "hdmi", canMute: false)
        hdmi.volume = 0.37
        let m = muter([hdmi])
        XCTAssertTrue(m.mute())
        XCTAssertEqual(hdmi.volume, 0)
        m.restore()
        XCTAssertEqual(hdmi.volume, 0.37)

        hdmi.volume = 0
        XCTAssertFalse(m.mute(), "already silent")
    }

    func testDeviceWithNoControlsIsUntouched() {
        let fixed = FakeDevice(uid: "fixed", canMute: false, canSetVolume: false)
        let m = muter([fixed])
        XCTAssertFalse(m.mute())
        XCTAssertFalse(m.isActive)
    }

    /// The device Gel muted is restored even after the default output changed.
    func testRestoresTheMutedDeviceAfterSwitch() {
        let speakers = FakeDevice(uid: "speakers"), airpods = FakeDevice(uid: "airpods")
        var current = speakers
        let m = OutputMuter(source: FakeSource(current: { current }, all: [speakers, airpods]), defaults: defaults)
        m.mute()
        current = airpods
        m.restore()
        XCTAssertFalse(speakers.isMuted)
        XCTAssertFalse(airpods.isMuted)
    }

    /// M5: a record left by a crash is undone by a fresh muter (next launch).
    func testCrashRecordRestoredOnNextLaunch() {
        let speakers = FakeDevice(uid: "speakers")
        muter([speakers]).mute()
        XCTAssertTrue(speakers.isMuted)
        let relaunched = muter([speakers])
        XCTAssertTrue(relaunched.isActive)
        relaunched.restore()
        XCTAssertFalse(speakers.isMuted)
    }
}
