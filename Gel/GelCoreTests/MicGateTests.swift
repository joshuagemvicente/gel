import XCTest
@testable import GelCore

final class MicGateTests: XCTestCase {
    func testGrantedRecords() {
        XCTAssertEqual(MicGate.step(for: .granted), .record)
    }

    func testUndeterminedAsks() {
        XCTAssertEqual(MicGate.step(for: .undetermined), .ask)
    }

    func testDeniedExplains() {
        XCTAssertEqual(MicGate.step(for: .denied), .explain(MicGate.deniedNotice))
        XCTAssertEqual(MicGate.deniedNotice, "Microphone access is off. Allow it in System Settings → Privacy → Microphone.")
    }

    func testRestrictedCountsAsDenied() {
        let restricted = MicGate.Access(authorizationStatus: 1)
        XCTAssertEqual(restricted, .denied)
        XCTAssertEqual(MicGate.step(for: restricted), .explain(MicGate.deniedNotice))
    }

    func testAuthorizationStatusMapping() {
        XCTAssertEqual(MicGate.Access(authorizationStatus: 0), .undetermined)
        XCTAssertEqual(MicGate.Access(authorizationStatus: 2), .denied)
        XCTAssertEqual(MicGate.Access(authorizationStatus: 3), .granted)
        XCTAssertEqual(MicGate.Access(authorizationStatus: 99), .denied)
    }

    func testPromptAnswerNotices() {
        XCTAssertEqual(MicGate.notice(afterAnswer: true), "Microphone on. Hold right ⌥ again to talk.")
        XCTAssertEqual(MicGate.notice(afterAnswer: false), MicGate.deniedNotice)
        XCTAssertEqual(MicGate.askingNotice, "Allow the microphone in the macOS prompt.")
    }

    func testDebugOverrideValuesParse() {
        XCTAssertEqual(MicGate.Access(rawValue: "granted"), .granted)
        XCTAssertEqual(MicGate.Access(rawValue: "undetermined"), .undetermined)
        XCTAssertEqual(MicGate.Access(rawValue: "denied"), .denied)
        XCTAssertNil(MicGate.Access(rawValue: "maybe"))
    }
}
