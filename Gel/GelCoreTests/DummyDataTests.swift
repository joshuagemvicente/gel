import XCTest
@testable import GelCore

/// R5 dummy replacement (D-073): fakes keep the kind and shape of the original, never equal it, and stay consistent.
final class DummyDataTests: XCTestCase {
    private func finding(_ text: String, type: String, category: String, at location: Int = 0) -> Finding {
        Finding(type: type, label: type.lowercased(), category: category, text: text,
                range: NSRange(location: location, length: (text as NSString).length), layer: 1)
    }

    func testIDsKeepTheirShape() {
        var rng = SystemRandomNumberGenerator()
        for (value, type) in [("04-4989449-2", "SSS"), ("120-629-110-00000", "TIN"), ("01-464611415-8", "PHILHEALTH"),
                              ("1430-2880-7080", "PAGIBIG"), ("P1234567A", "PASSPORT"), ("4000 0566 5566 5556", "CARD")] {
            let fake = DummyData.fake(for: finding(value, type: type, category: type == "CARD" ? "card" : "government ID"), using: &rng)
            XCTAssertEqual(fake.count, value.count, fake)
            XCTAssertNotEqual(fake, value)
            for (a, b) in zip(fake, value) {
                XCTAssertEqual(a.isNumber, b.isNumber, fake)
                XCTAssertEqual(a.isLetter, b.isLetter, fake)
                if !b.isLetter && !b.isNumber { XCTAssertEqual(a, b, fake) }
            }
        }
    }

    func testPhoneKeepsThePrefix() {
        var rng = SystemRandomNumberGenerator()
        let fake = DummyData.fake(for: finding("0935 670 4410", type: "PHONE", category: "contact"), using: &rng)
        XCTAssertTrue(fake.hasPrefix("09"), fake)
        XCTAssertEqual(fake.count, 13)
    }

    func testNamesAreFictionalAndKeepCase() {
        var rng = SystemRandomNumberGenerator()
        let plain = DummyData.fake(for: finding("Liza Velasco", type: "NAME", category: "name"), using: &rng)
        XCTAssertEqual(plain.split(separator: " ").count, 2, plain)
        XCTAssertFalse(DummyData.isAllCaps(plain))
        let caps = DummyData.fake(for: finding("CARLO M. VELASCO", type: "NAME", category: "name"), using: &rng)
        XCTAssertTrue(DummyData.isAllCaps(caps), caps)
        XCTAssertEqual(caps.split(separator: " ").count, 3, caps)
        let listed = DummyData.fake(for: finding("Velasco, Carlo", type: "NAME", category: "name"), using: &rng)
        XCTAssertTrue(listed.contains(","), listed)
        // None of the fake surnames are demo-data people.
        for demo in ["Reyes", "Santos", "Cruz", "Velasco", "Javier", "Buenaventura", "Ramos", "Tolentino"] {
            XCTAssertFalse(DummyData.lastNames.contains(demo))
            XCTAssertFalse(DummyData.firstNames.contains(demo))
        }
    }

    func testAmountsAndDatesKeepTheirFormat() {
        var rng = SystemRandomNumberGenerator()
        let peso = DummyData.fake(for: finding("₱45,000.00", type: "SALARY", category: "salary"), using: &rng)
        XCTAssertNotNil(peso.range(of: "^₱\\d{2},\\d{3}\\.00$", options: .regularExpression), peso)
        let ocr = DummyData.fake(for: finding("P18.000.00", type: "SALARY", category: "salary"), using: &rng)
        XCTAssertNotNil(ocr.range(of: "^P\\d{2}\\.\\d{3},00$", options: .regularExpression), ocr)
        let slash = DummyData.fake(for: finding("02/06/1989", type: "DOB", category: "date of birth"), using: &rng)
        XCTAssertNotNil(slash.range(of: "^\\d{2}/\\d{2}/\\d{4}$", options: .regularExpression), slash)
        let iso = DummyData.fake(for: finding("2026-09-30", type: "DATE", category: "date of birth"), using: &rng)
        XCTAssertNotNil(iso.range(of: "^\\d{4}-\\d{2}-\\d{2}$", options: .regularExpression), iso)
        let long = DummyData.fake(for: finding("September 29, 2026", type: "DATE", category: "date of birth"), using: &rng)
        XCTAssertNotNil(long.range(of: "^[A-Z][a-z]+ \\d{1,2}, \\d{4}$", options: .regularExpression), long)
    }

    func testOtherValuesBecomeLorem() {
        var rng = SystemRandomNumberGenerator()
        let fake = DummyData.fake(for: finding("Project Bayanihan Phase 2", type: "CUSTOM", category: "added by you"), using: &rng)
        XCTAssertGreaterThanOrEqual(fake.count, 20, fake)
        XCTAssertFalse(fake.contains("Bayanihan"))
    }

    func testRedactTextDummyModeIsConsistentAndKeepsNothingOriginal() {
        let text = "SSS 04-4989449-2 for Liza Velasco, again 04-4989449-2 and Liza Velasco."
        let findings = PIIDetector.shared.detectFast(text, packs: ["hr"])
        let r = Redactor.redactText(text, findings: findings, mode: .dummy)
        XCTAssertFalse(r.text.contains("04-4989449-2"), r.text)
        XCTAssertFalse(r.text.contains("Velasco"), r.text)
        XCTAssertFalse(r.text.contains("["), r.text)
        // The same value gets the same fake both times, and the fake maps back to the original.
        let fakeSSS = r.mapping.first { $0.value == "04-4989449-2" }!.key
        XCTAssertEqual(r.text.components(separatedBy: fakeSSS).count, 3, r.text)
        XCTAssertNotNil(fakeSSS.range(of: "^\\d{2}-\\d{7}-\\d$", options: .regularExpression), fakeSSS)
    }

    func testReplacementsExtendWithoutChangingEarlierFakes() {
        let a = finding("04-4989449-2", type: "SSS", category: "government ID", at: 0)
        let b = finding("Liza Velasco", type: "NAME", category: "name", at: 20)
        let first = DummyData.replacements(for: [a])
        let second = DummyData.replacements(for: [a, b], existing: first)
        XCTAssertEqual(second["04-4989449-2"], first["04-4989449-2"])
        XCTAssertNotNil(second["liza velasco"])
    }
}

/// R6 "Add something Gel missed": the literal path is instant and offline.
final class CustomFindingsTests: XCTestCase {
    func testLiteralMatchesEveryOccurrenceCaseInsensitively() {
        let text = "Bayanihan Outsourcing Corp. hired her; BAYANIHAN OUTSOURCING pays monthly."
        let f = PIIDetector.customFindings("bayanihan outsourcing", in: text)
        XCTAssertEqual(f.count, 2)
        XCTAssertEqual(f.map(\.text), ["Bayanihan Outsourcing", "BAYANIHAN OUTSOURCING"])
        XCTAssertTrue(f.allSatisfy { $0.category == PIIDetector.addedCategory && $0.type == "CUSTOM" && $0.layer == 4 })
        XCTAssertEqual(Redactor.redactText(text, findings: f).text,
                       "[CUSTOM_1] Corp. hired her; [CUSTOM_1] pays monthly.")
    }

    func testLiteralIgnoresTinyOrMissingValues() {
        XCTAssertTrue(PIIDetector.customFindings("x", in: "x marks the spot").isEmpty)
        XCTAssertTrue(PIIDetector.customFindings("payroll", in: "nothing here").isEmpty)
    }
}
