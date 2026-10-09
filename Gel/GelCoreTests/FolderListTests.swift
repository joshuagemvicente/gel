import XCTest
@testable import GelCore

final class FolderListTests: XCTestCase {
    func testDuplicateIsIgnored() {
        let r = FolderList.adding(["/a/HR/", "/a/HR"], to: ["/a/HR"])
        XCTAssertEqual(r.list, ["/a/HR"])
        XCTAssertEqual(r.notes, [])
    }

    func testChildIsNotAdded() {
        let r = FolderList.adding(["/a/HR/Scans"], to: ["/a/HR"])
        XCTAssertEqual(r.list, ["/a/HR"])
        XCTAssertEqual(r.notes, [.alreadyIncluded(child: "/a/HR/Scans", parent: "/a/HR")])
    }

    func testParentReplacesChildrenInPlace() {
        let r = FolderList.adding(["/a"], to: ["/z", "/a/HR", "/a/Personal"])
        XCTAssertEqual(r.list, ["/z", "/a"])
        XCTAssertEqual(r.notes, [.replaced(parent: "/a", count: 2)])
    }

    func testSiblingWithSharedPrefixIsSeparate() {
        let r = FolderList.adding(["/x/HR Files"], to: ["/x/HR"])
        XCTAssertEqual(r.list, ["/x/HR", "/x/HR Files"])
        XCTAssertFalse(FolderList.contains("/x/HR", "/x/HR Files/a.pdf"))
        XCTAssertTrue(FolderList.contains("/x/HR", "/x/HR/a.pdf"))
    }

    func testSeveralAtOnce() {
        let r = FolderList.adding(["/b", "/c", "/b/sub"], to: [])
        XCTAssertEqual(r.list, ["/b", "/c"])
        XCTAssertEqual(r.notes, [.alreadyIncluded(child: "/b/sub", parent: "/b")])
    }

    // AC6: pruning a file deleted from /x/HR must leave every /x/HR Files document.
    func testPruneDoesNotCrossSiblingPrefix() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("gel-folders-\(UUID().uuidString)")
        let hr = root.appendingPathComponent("HR"), hrFiles = root.appendingPathComponent("HR Files")
        for dir in [hr, hrFiles] { try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true) }
        defer { try? FileManager.default.removeItem(at: root) }
        for url in [hr.appendingPathComponent("keep.txt"), hrFiles.appendingPathComponent("other.txt")] {
            try "x".write(to: url, atomically: true, encoding: .utf8)
        }
        let store = try Store(url: root.appendingPathComponent("index.sqlite"))
        let paths = [hr.appendingPathComponent("keep.txt").path, hr.appendingPathComponent("gone.txt").path,
                     hrFiles.appendingPathComponent("other.txt").path, hrFiles.appendingPathComponent("not-on-disk.txt").path]
        for p in paths { try store.save(path: p, kind: .text, modified: Date(), pages: [], chunks: []) }

        let indexer = Indexer(store: store)
        indexer.pruneMissing(in: hr)
        XCTAssertEqual(Set(store.documents().map(\.path)), Set([paths[0], paths[2], paths[3]]))

        indexer.pruneOutside([hrFiles])
        XCTAssertEqual(Set(store.documents().map(\.path)), Set([paths[2], paths[3]]))
    }

    // AC4: the old single folder becomes the list; GEL_FOLDER (":"-separated) overrides it.
    func testUpgradeAndEnvironmentOverride() throws {
        let suite = "gel-tests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("/a/HR Files", forKey: "folderPath")

        let settings = GelSettings(defaults: defaults, env: [:])
        XCTAssertEqual(settings.folderPaths, ["/a/HR Files"])
        settings.folderPaths = ["/a/HR Files", "/b"]
        XCTAssertEqual(GelSettings(defaults: defaults, env: [:]).folderPaths, ["/a/HR Files", "/b"])

        let overridden = GelSettings(defaults: defaults, env: ["GEL_FOLDER": "/x:/y/"])
        XCTAssertTrue(overridden.folderPathsFromEnvironment)
        XCTAssertEqual(overridden.folderPaths, ["/x", "/y"])
    }
}
