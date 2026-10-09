import XCTest
@testable import GelCore

final class ModelSetupTests: XCTestCase {

    // MARK: - Pull progress

    func testAggregatesLayersAndFinishes() throws {
        var agg = PullAggregator()
        try agg.consume(#"{"status":"pulling manifest"}"#)
        XCTAssertEqual(agg.progress.fraction, 0)
        try agg.consume(#"{"status":"pulling a","digest":"sha256:a","total":300}"#)
        try agg.consume(#"{"status":"pulling b","digest":"sha256:b","total":100,"completed":50}"#)
        let p = try agg.consume(#"{"status":"pulling a","digest":"sha256:a","total":300,"completed":150}"#)
        XCTAssertEqual(p.total, 400)
        XCTAssertEqual(p.completed, 200)
        XCTAssertEqual(p.fraction, 0.5, accuracy: 0.0001)
        XCTAssertFalse(p.done)
        // A layer line without "completed" keeps that layer's last value.
        XCTAssertEqual(try agg.consume(#"{"status":"pulling b","digest":"sha256:b","total":100}"#).completed, 200)
        try agg.consume(#"{"status":"verifying sha256 digest"}"#)
        let end = try agg.consume(#"{"status":"success"}"#)
        XCTAssertTrue(end.done)
        XCTAssertEqual(end.fraction, 1)
    }

    func testErrorLineThrows() {
        var agg = PullAggregator()
        XCTAssertThrowsError(try agg.consume(#"{"error":"pull model manifest: file does not exist"}"#)) { error in
            XCTAssertEqual(error as? OllamaError, .server("pull model manifest: file does not exist"))
        }
    }

    func testIgnoresBlankAndGarbageLines() throws {
        var agg = PullAggregator()
        XCTAssertEqual(try agg.consume(""), PullProgress())
        XCTAssertEqual(try agg.consume("not json"), PullProgress())
    }

    // MARK: - Pull over HTTP (stubbed)

    private func stubSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubPull.self]
        return URLSession(configuration: config)
    }

    func testPullStreamsToSuccess() async throws {
        StubPull.lines = [#"{"status":"pulling a","digest":"d","total":10,"completed":5}"#,
                          #"{"status":"pulling a","digest":"d","total":10,"completed":10}"#,
                          #"{"status":"success"}"#]
        StubPull.hang = false
        let seen = Box<[Double]>([])
        try await OllamaAPI.pull("m", baseURL: "http://stub", session: stubSession()) { seen.value.append($0.fraction) }
        XCTAssertEqual(seen.value, [0.5, 1, 1])
    }

    func testPullWithoutSuccessIsIncomplete() async {
        StubPull.lines = [#"{"status":"pulling a","digest":"d","total":10,"completed":5}"#]
        StubPull.hang = false
        do {
            try await OllamaAPI.pull("m", baseURL: "http://stub", session: stubSession()) { _ in }
            XCTFail("expected incomplete")
        } catch { XCTAssertEqual(error as? OllamaError, .incomplete) }
    }

    func testCancellingStopsThePull() async {
        StubPull.lines = [#"{"status":"pulling a","digest":"d","total":10,"completed":1}"#]
        StubPull.hang = true
        let session = stubSession()
        let task = Task {
            try await OllamaAPI.pull("m", baseURL: "http://stub", session: session) { _ in }
        }
        try? await Task.sleep(for: .milliseconds(300))
        task.cancel()
        let result = await task.result
        guard case .failure(let error) = result else { return XCTFail("expected cancellation") }
        XCTAssertTrue(error is CancellationError || (error as? URLError)?.code == .cancelled, "\(error)")
    }

    // MARK: - Catalog

    func testCatalogGuards() {
        let qwen = ModelCatalog.presets[0]
        XCTAssertTrue(ModelCatalog.lacksRAM(qwen, memoryGB: 4))
        XCTAssertFalse(ModelCatalog.lacksRAM(qwen, memoryGB: 8))
        XCTAssertTrue(ModelCatalog.lacksDisk(needed: 2_000_000_000, free: 2_500_000_000))
        XCTAssertFalse(ModelCatalog.lacksDisk(needed: 2_000_000_000, free: 3_500_000_000))
        XCTAssertTrue(ModelCatalog.isInstalled("bge-m3", in: ["bge-m3:latest"]))
        XCTAssertEqual(ModelCatalog.preset(for: GelSettings.defaultLocalModel)?.tier, .balanced)
        XCTAssertTrue(ModelCatalog.presets.allSatisfy { $0.firstWordsSeconds != nil }, "every shipped preset is measured")
    }

    func testEnvironmentLocksModel() {
        let d = UserDefaults(suiteName: "gel.tests.models.\(UUID().uuidString)")!
        XCTAssertFalse(GelSettings(defaults: d, env: [:]).localModelFromEnvironment)
        let pinned = GelSettings(defaults: d, env: ["GEL_LOCAL_MODEL": "x:1b"])
        XCTAssertTrue(pinned.localModelFromEnvironment)
        XCTAssertEqual(pinned.localModel, "x:1b")
    }
}

private final class Box<T>: @unchecked Sendable {
    var value: T
    init(_ value: T) { self.value = value }
}

/// Serves `lines` as an NDJSON body; with `hang`, never finishes, so only cancellation ends the request.
private final class StubPull: URLProtocol {
    nonisolated(unsafe) static var lines: [String] = []
    nonisolated(unsafe) static var hang = false

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        for line in Self.lines { client?.urlProtocol(self, didLoad: Data((line + "\n").utf8)) }
        if !Self.hang { client?.urlProtocolDidFinishLoading(self) }
    }

    override func stopLoading() {}
}
