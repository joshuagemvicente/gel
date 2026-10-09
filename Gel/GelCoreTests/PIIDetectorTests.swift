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
        let safe = try Redactor.cloudSafe(raw)
        for value in ["34-5678901-2", "₱28,500.00", "1234-5678-90"] { XCTAssertFalse(safe.contains(value), value) }
    }

    /// D-072: the gate ignores which packs are active. A Personal-only user's payslip still loses its HR-pack IDs.
    func testCloudGateCoversInactivePacks() throws {
        let raw = "SSS NO. 04-4989449-2 TIN 120-629-110-00000 PHILHEALTH 01-464611415-8 PAG-IBIG 1430-2880-7080 Passport P1234567A"
        let gated = try Redactor.cloudGate(raw)
        for value in ["04-4989449-2", "120-629-110-00000", "01-464611415-8", "1430-2880-7080", "P1234567A"] {
            XCTAssertFalse(gated.text.contains(value), value)
        }
        XCTAssertEqual(gated.mapping["[SSS_1]"], "04-4989449-2")
        XCTAssertTrue(PIIDetector.shared.packStore.allPackIds.contains("hr"))
        XCTAssertTrue(PIIDetector.shared.packStore.allPackIds.contains("personal"))
    }

    /// D-072: a longer "Surname, Title" span must not throw away the real name it overlaps.
    func testCloudGateUnionsOverlappingNames() throws {
        for (raw, leak) in [("FROM\nLiza T. Buenaventura, HR Director\nDATE", "Liza"),
                            ("Approved by Jerome Q. Ramos, Finance Manager on 2026-09-01", "Jerome"),
                            ("Prepared by: Kristine Joy Reyes, Payroll Specialist", "Joy")] {
            let safe = try Redactor.cloudSafe(raw)
            XCTAssertFalse(safe.contains(leak), safe)
        }
        let safe = try Redactor.cloudSafe("FROM\nLiza T. Buenaventura, HR Director\nDATE")
        XCTAssertEqual(safe, "FROM\n[NAME_1]\nDATE")
    }

    /// D-072: dates are redacted for the cloud even when their label sits on another OCR line (Q4).
    func testCloudGateRedactsBareDates() throws {
        let raw = "NAME\nRELATIONSHIP\nDATE OF BIRTH\nLiza Velasco\nSpouse\n02/06/1989\nHired 2026-09-30, memo of September 29, 2026\nPayroll 2017–2024"
        let safe = try Redactor.cloudSafe(raw)
        for value in ["02/06/1989", "2026-09-30", "September 29, 2026"] { XCTAssertFalse(safe.contains(value), safe) }
        XCTAssertTrue(safe.contains("2017–2024"), safe)
        // IDs keep their own type; a date pattern must not bite into them.
        let ids = try Redactor.cloudGate("TIN 120-629-110-00000 SSS 04-4989449-2 born 06/18/1989")
        XCTAssertEqual(ids.mapping["[TIN_1]"], "120-629-110-00000")
        XCTAssertEqual(ids.mapping["[SSS_1]"], "04-4989449-2")
        XCTAssertFalse(ids.text.contains("06/18/1989"))
    }

    func testSummary() {
        let text = "SSS 34-5678901-2 TIN 123-456-789-000 PhilHealth 12-345678901-2 salary ₱28,500.00"
        let s = PIIDetector.summary(detector.detectFast(text, packs: ["hr"]))
        XCTAssertTrue(s.hasPrefix("3 government ID numbers, 1 salary"), s)
    }

    func testCitationNumbers() {
        XCTAssertEqual(QueryEngine.citationNumbers(in: "Reyes [2] and Cruz [1][2]."), [2, 1])
        XCTAssertEqual(QueryEngine.citationNumbers(in: "Both [3, 1] and [4]."), [3, 1, 4])
        XCTAssertEqual(QueryEngine.citationMarkers(in: "a [1][2] b").count, 2)
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
        let r = try Redactor.cloudGate(raw)
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

    func testOnePassGateKeepsSystemAndNumbersOnce() throws {
        let system = "Rules:\n- Use ONLY the numbered sources. Answer in English, Filipino or Taglish."
        let messages: [ChatMessage] = [.system(system), .user("<source n=\"1\">\nPatricia Anne Cruz\nPayroll Lead\n</source>\nWho has payroll?")]
        let (out, mapping) = try ModelRouter.redact(messages, with: QueryEngine.cloudGate)
        XCTAssertEqual(out[0].content, system)
        XCTAssertFalse(out[1].content.contains("Patricia"))
        XCTAssertEqual(mapping["[NAME_1]"], "Patricia Anne Cruz")
        XCTAssertEqual(Redactor.rehydrate("[NAME_1] has 9 years [1].", mapping: mapping), "Patricia Anne Cruz has 9 years [1].")
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

    func testLibraryQuestions() {
        XCTAssertTrue(QueryEngine.isLibraryQuestion("How many files do I have?"))
        XCTAssertTrue(QueryEngine.isLibraryQuestion("Ilang files meron ako?"))
        XCTAssertTrue(QueryEngine.isLibraryQuestion("how many documents are in my library"))
        XCTAssertFalse(QueryEngine.isLibraryQuestion("How many files mention payroll?"))
        XCTAssertFalse(QueryEngine.isLibraryQuestion("Ilan ang empleyado sa Operations?"))
        XCTAssertFalse(QueryEngine.isLibraryQuestion("Who maintains 201 files?"))
    }

    func testNotFoundBothLanguages() {
        XCTAssertTrue(QueryEngine.isNotFound("Hindi ko nakita sa files."))
        XCTAssertTrue(QueryEngine.isNotFound("I couldn't find that in your files."))
        XCTAssertFalse(QueryEngine.isNotFound("Patricia Anne Cruz [1]"))
    }
}
