import XCTest
@testable import GelCore

final class PIIDetectorTests: XCTestCase {
    let detector = PIIDetector.shared

    func types(_ text: String, packs: [String] = ["hr", "personal"]) -> [String: String] {
        Dictionary(PIIDetector.merge(detector.patternFindings(text, packs: packs)).map { ($0.text, $0.type) }, uniquingKeysWith: { a, _ in a })
    }

    func testPhilippineGovernmentIDs() {
        let t = types("SSS: 34-5678901-2 TIN: 123-456-789-000 PhilHealth: 12-345678901-2 Pag-IBIG: 1234-5678-9012")
        XCTAssertEqual(t["34-5678901-2"], "SSS")
        XCTAssertEqual(t["123-456-789-000"], "TIN")
        XCTAssertEqual(t["12-345678901-2"], "PHILHEALTH")
        XCTAssertEqual(t["1234-5678-9012"], "PAGIBIG")
    }

    func testPhilSysWinsOverPagIbigShape() {
        let merged = PIIDetector.merge(detector.patternFindings("PSN 1234-5678-9012-3456", packs: ["personal", "hr"]))
        XCTAssertEqual(merged.count, 1)
        XCTAssertEqual(merged.first?.type, "PHILSYS")
    }

    func testPersonalIDsAndMoney() {
        let t = types("Passport No. P1234567A, License N01-23-456789, GCash 0917 123 4567, balance ₱125,430.50",
                      packs: ["personal"])
        XCTAssertEqual(t["P1234567A"], "PASSPORT")
        XCTAssertEqual(t["N01-23-456789"], "DRIVERS_LICENSE")
        XCTAssertEqual(t["0917 123 4567"], "GCASH")
        XCTAssertEqual(t["₱125,430.50"], "AMOUNT")
    }

    func testCardNeedsLuhn() {
        XCTAssertTrue(PIIDetector.luhn("4000 0566 5566 5556"))
        XCTAssertFalse(PIIDetector.luhn("4000 0566 5566 5557"))
        let t = types("Card 4000 0566 5566 5556 and fake 4000 0566 5566 5557", packs: ["personal"])
        XCTAssertEqual(t["4000 0566 5566 5556"], "CARD")
        XCTAssertNil(t["4000 0566 5566 5557"])
    }

    func testCoreContactsAlwaysOn() {
        let t = types("Email juan.delacruz@example-mail.ph, mobile +63 917 555 0123", packs: [])
        XCTAssertEqual(t["juan.delacruz@example-mail.ph"], "EMAIL")
        XCTAssertEqual(t["+63 917 555 0123"], "PHONE")
    }

    func testRedactTextUsesConsistentPlaceholders() {
        let text = "SSS 34-5678901-2 then again 34-5678901-2"
        let r = Redactor.redactText(text, findings: detector.detectFast(text, packs: ["hr"]))
        XCTAssertEqual(r.text, "SSS [SSS_1] then again [SSS_1]")
        XCTAssertEqual(r.mapping["[SSS_1]"], "34-5678901-2")
    }

    func testCloudSafeRemovesIDs() throws {
        let raw = "Employee: Maria Santos, SSS 34-5678901-2, salary ₱28,500.00, account no. 1234-5678-90"
        let safe = try Redactor.cloudSafe(raw, packs: ["hr"])
        for value in ["34-5678901-2", "₱28,500.00", "1234-5678-90"] { XCTAssertFalse(safe.contains(value), value) }
    }

    func testSummary() {
        let text = "SSS 34-5678901-2 TIN 123-456-789-000 PhilHealth 12-345678901-2 salary ₱28,500.00"
        let s = PIIDetector.summary(detector.detectFast(text, packs: ["hr"]))
        XCTAssertTrue(s.hasPrefix("3 government ID numbers, 1 salary"), s)
    }

    func testCitationNumbers() {
        XCTAssertEqual(QueryEngine.citationNumbers(in: "Reyes [2] and Cruz [1][2]."), [2, 1])
    }

    func testChunkerCoversText() {
        let text = String(repeating: "Payroll Specialist 2017 to 2024. ", count: 80)
        let chunks = Chunker.chunks(for: text)
        XCTAssertGreaterThan(chunks.count, 1)
        XCTAssertEqual(chunks.first?.start, 0)
        XCTAssertEqual((chunks.last!.start + chunks.last!.length), (text as NSString).length)
    }
}

final class CloudGateTests: XCTestCase {
    func testMappingAndRehydrate() throws {
        let raw = "Applicant Kristine Joy Reyes, SSS 25-6708763-7, expected salary ₱45,000.00"
        let r = try Redactor.cloudSafeWithMapping(raw, packs: ["hr"])
        XCTAssertFalse(r.text.contains("25-6708763-7"))
        XCTAssertFalse(r.text.contains("₱45,000.00"))
        // A cloud answer using the placeholders is shown with the real values locally.
        let cloudAnswer = "The SSS number is [SSS_1] and the salary is [SALARY_1]."
        let shown = Redactor.rehydrate(cloudAnswer, mapping: r.mapping)
        XCTAssertTrue(shown.contains("25-6708763-7"))
        XCTAssertTrue(shown.contains("₱45,000.00"))
    }

    func testRehydratePrefersLongestToken() {
        let shown = Redactor.rehydrate("[NAME_12] and [NAME_1]", mapping: ["[NAME_1]": "Ana", "[NAME_12]": "Ben"])
        XCTAssertEqual(shown, "Ben and Ana")
    }

    func testGateFailureMeansNoRequest() {
        struct Boom: Error {}
        XCTAssertThrowsError(try ModelRouter.redact([.user("SSS 25-6708763-7")], with: { _ in throw Boom() })) { error in
            guard case LLMError.redactionFailed = error else { return XCTFail("expected redactionFailed") }
        }
    }

    func testBroadQuestionDetection() {
        XCTAssertTrue(QueryEngine.isBroad("Ilan ang empleyado sa Operations?"))
        XCTAssertFalse(QueryEngine.isBroad("Sino sa applicants ang may 5+ years sa payroll?"))
    }
}

final class QuestionKindTests: XCTestCase {
    func testRankingDetectionAndCount() {
        let q = "I want you to find five employment resumes that has the best HR resume."
        XCTAssertEqual(QueryEngine.kind(of: q), .ranking)
        XCTAssertEqual(QueryEngine.requestedCount(q), 5)
        XCTAssertEqual(QueryEngine.kind(of: "Sino ang pinakamagaling sa payroll?"), .ranking)
        XCTAssertEqual(QueryEngine.kind(of: "Sino sa applicants ang may 5+ years sa payroll?"), .fact)
        XCTAssertEqual(QueryEngine.requestedCount("Hanapin ang lima na pinakamagaling"), 5)
    }

    func testFilipinoDetection() {
        XCTAssertTrue(QueryEngine.isFilipino("Ano ang paboritong pagkain ni Reyes?"))
        XCTAssertFalse(QueryEngine.isFilipino("Who has payroll experience?"))
    }

    func testNotFoundBothLanguages() {
        XCTAssertTrue(QueryEngine.isNotFound("Hindi ko nakita sa files."))
        XCTAssertTrue(QueryEngine.isNotFound("I couldn't find that in your files."))
        XCTAssertFalse(QueryEngine.isNotFound("Patricia Anne Cruz [1]"))
    }
}
