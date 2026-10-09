import Foundation

/// The folders Gel reads. Kept free of duplicates and nesting, so every indexed document sits under exactly one entry.
public enum FolderList {
    public enum Note: Equatable {
        /// `child` wasn't added because `parent` already covers it.
        case alreadyIncluded(child: String, parent: String)
        /// `parent` replaced `count` listed folders that sit inside it.
        case replaced(parent: String, count: Int)
    }

    /// Absolute, standardized, no trailing slash.
    public static func standardize(_ path: String) -> String {
        var p = URL(fileURLWithPath: path).standardizedFileURL.path
        while p.count > 1 && p.hasSuffix("/") { p.removeLast() }
        return p
    }

    /// True when `path` is `folder` or anywhere below it. Compares with a trailing "/" so "/x/HR" never matches "/x/HR Files".
    public static func contains(_ folder: String, _ path: String) -> Bool {
        path == folder || path.hasPrefix(folder == "/" ? "/" : folder + "/")
    }

    /// Adds folders in order: duplicates are ignored, a folder inside a listed one is skipped, and a folder that contains
    /// listed ones takes the place of the first of them.
    public static func adding(_ new: [String], to list: [String]) -> (list: [String], notes: [Note]) {
        var result = list.map(standardize)
        var notes: [Note] = []
        for raw in new {
            let p = standardize(raw)
            if result.contains(p) { continue }
            if let parent = result.first(where: { contains($0, p) }) {
                notes.append(.alreadyIncluded(child: p, parent: parent))
                continue
            }
            let children = result.filter { contains(p, $0) }
            if let first = children.first, let at = result.firstIndex(of: first) {
                result.removeAll { children.contains($0) }
                result.insert(p, at: min(at, result.count))
                notes.append(.replaced(parent: p, count: children.count))
            } else {
                result.append(p)
            }
        }
        return (result, notes)
    }
}
