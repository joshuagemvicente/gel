import Foundation
import NaturalLanguage

public struct PIIType: Codable, Hashable {
    public var id: String
    public var label: String
    public var category: String
    public var pattern: String
    public var group: Int?
    public var validator: String?
}

public struct Pack: Codable, Hashable, Identifiable {
    public var id: String
    public var name: String
    public var description: String
    public var audience: String?
    public var alwaysOn: Bool?
    public var types: [PIIType]
    public var sampleQuestions: [String]?
}

public struct Finding: Hashable, Codable, Identifiable {
    public var id: String { "\(range.location)-\(range.length)-\(type)" }
    public var type: String
    public var label: String
    public var category: String
    public var text: String
    /// UTF-16 range in the scanned text.
    public var range: NSRange
    /// 1 = pattern, 2 = name detection, 3 = LLM.
    public var layer: Int
}

/// Loads packs: the ones bundled with Gel plus any JSON dropped into Application Support/Gel/Packs.
public final class PackStore {
    public static let shared = PackStore()
    public private(set) var packs: [Pack] = []

    public init() { reload() }

    public func reload() {
        var urls = Bundle(for: PackStore.self).urls(forResourcesWithExtension: "json", subdirectory: nil)?
            .filter { $0.lastPathComponent.hasPrefix("pack_") } ?? []
        let custom = GelPaths.home.appendingPathComponent("Packs", isDirectory: true)
        if let extra = try? FileManager.default.contentsOfDirectory(at: custom, includingPropertiesForKeys: nil) {
            urls += extra.filter { $0.pathExtension == "json" }
        }
        var byId: [String: Pack] = [:]
        for url in urls {
            if let data = try? Data(contentsOf: url), let pack = try? JSONDecoder().decode(Pack.self, from: data) {
                byId[pack.id] = pack
            }
        }
        packs = byId.values.sorted { ($0.alwaysOn == true ? 0 : 1, $0.name) < ($1.alwaysOn == true ? 0 : 1, $1.name) }
    }

    public var selectablePacks: [Pack] { packs.filter { $0.alwaysOn != true } }

    public func types(active: [String]) -> [PIIType] {
        let chosen = packs.filter { $0.alwaysOn == true || active.contains($0.id) }
        var seen = Set<String>()
        var result: [PIIType] = []
        for t in chosen.flatMap(\.types) where seen.insert(t.id + t.pattern).inserted { result.append(t) }
        return result
    }
}

/// Finds personal data in three layers: (1) pack patterns, (2) Apple's on-device name tagger, (3) an LLM pass for
/// context like addresses and salaries. Layers 1–2 are instant and never touch the network.
public final class PIIDetector {
    public static let shared = PIIDetector()
    public var packStore = PackStore.shared
    private var regexCache: [String: NSRegularExpression] = [:]
    private let cacheLock = NSLock()

    public init() {}

    private func regex(_ pattern: String) -> NSRegularExpression? {
        cacheLock.lock(); defer { cacheLock.unlock() }
        if let r = regexCache[pattern] { return r }
        let r = try? NSRegularExpression(pattern: pattern)
        regexCache[pattern] = r
        return r
    }

    // MARK: Layer 1 — patterns

    public func patternFindings(_ text: String, packs: [String]) -> [Finding] {
        let ns = text as NSString
        var out: [Finding] = []
        for type in packStore.types(active: packs) {
            guard let re = regex(type.pattern) else { continue }
            for m in re.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
                let g = type.group ?? 0
                guard g < m.numberOfRanges else { continue }
                var r = m.range(at: g)
                guard r.location != NSNotFound, r.length > 0 else { continue }
                var value = ns.substring(with: r)
                // Trim trailing punctuation/space picked up by greedy patterns.
                while let last = value.unicodeScalars.last,
                      CharacterSet.whitespaces.union(CharacterSet(charactersIn: ".,;")).contains(last) {
                    value.removeLast(); r.length -= 1
                }
                if type.validator == "luhn" && !Self.luhn(value) { continue }
                out.append(Finding(type: type.id, label: type.label, category: type.category, text: value, range: r, layer: 1))
            }
        }
        return out
    }

    static func luhn(_ s: String) -> Bool {
        let digits = s.compactMap { $0.wholeNumberValue }
        guard digits.count >= 13 else { return false }
        var sum = 0
        for (i, d) in digits.reversed().enumerated() {
            if i % 2 == 1 { let x = d * 2; sum += x > 9 ? x - 9 : x } else { sum += d }
        }
        return sum % 10 == 0
    }

    // MARK: Layer 2 — names and places (NaturalLanguage, on-device)

    public func nameFindings(_ text: String, seeds extraSeeds: [String] = []) -> [Finding] {
        // The tagger misses ALL-CAPS names ("KRISTINE JOY REYES"), so also scan a title-cased copy.
        // Title-casing keeps every UTF-16 offset, so ranges map back to the original text.
        let titled = Self.titleCaseAllCaps(text)
        var found = tagNames(text, original: text)
        if titled != text { found += tagNames(titled, original: text) }
        // Email local parts ("jasmine.tolentino@…") are reliable name seeds when the tagger finds nothing.
        var seeds = found.map(\.text) + extraSeeds
        if let email = try? NSRegularExpression(pattern: "([A-Za-z]+[._-][A-Za-z._-]+?)[0-9]*@") {
            let ns = text as NSString
            for m in email.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
                seeds.append(ns.substring(with: m.range(at: 1)).replacingOccurrences(of: "_", with: " ").replacingOccurrences(of: ".", with: " "))
            }
        }
        return found + propagateNames(seeds, in: text)
    }

    /// Finds variants of already-found names: runs of 2–4 capitalized words/initials that share at least two
    /// name parts (3+ letters) with a known name, e.g. "Jerome Q. Ramos" after "JEROME QUIAMBAO RAMOS".
    func propagateNames(_ names: [String], in text: String) -> [Finding] {
        let parts = Set(names.flatMap { $0.lowercased().components(separatedBy: CharacterSet.letters.inverted) }.filter { $0.count >= 3 })
        guard parts.count >= 2,
              let re = try? NSRegularExpression(pattern: "\\b[A-ZÑ][A-Za-zÑñ'-]*\\.?(?:[ \\t]+[A-ZÑ][A-Za-zÑñ'-]*\\.?){1,3}") else { return [] }
        let ns = text as NSString
        var out: [Finding] = []
        for m in re.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
            let value = ns.substring(with: m.range).trimmingCharacters(in: CharacterSet(charactersIn: ". "))
            let words = value.lowercased().components(separatedBy: CharacterSet.letters.inverted).filter { $0.count >= 3 }
            if Set(words).intersection(parts).count >= 2 {
                out.append(Finding(type: "NAME", label: "name", category: "name", text: value,
                                   range: NSRange(location: m.range.location, length: (value as NSString).length), layer: 2))
            }
        }
        return out
    }

    static func titleCaseAllCaps(_ text: String) -> String {
        let ns = NSMutableString(string: text)
        guard let re = try? NSRegularExpression(pattern: "\\b[A-ZÑ][A-ZÑ'-]+\\b") else { return text }
        for m in re.matches(in: text, range: NSRange(location: 0, length: ns.length)).reversed() {
            let word = ns.substring(with: m.range)
            let titled = word.prefix(1) + word.dropFirst().lowercased()
            if (titled as NSString).length == m.range.length { ns.replaceCharacters(in: m.range, with: String(titled)) }
        }
        return ns as String
    }

    private func tagNames(_ text: String, original: String) -> [Finding] {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        var out: [Finding] = []
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: options) { tag, range in
            guard let tag, tag == .personalName else { return true }
            let nsRange = NSRange(range, in: text)
            let value = (original as NSString).substring(with: nsRange)
            // Single short tokens are often false positives ("Payroll", "Manila"); require 2+ words for names.
            guard value.split(separator: " ").count >= 2 || value.count >= 6 else { return true }
            out.append(Finding(type: "NAME", label: "name", category: "name", text: value, range: nsRange, layer: 2))
            return true
        }
        return out
    }

    /// Layers 1 + 2. Instant, offline; used for Leak Guard and for redacting anything sent to the cloud.
    public func detectFast(_ text: String, packs: [String] = GelSettings.shared.activePacks) -> [Finding] {
        let patterns = patternFindings(text, packs: packs)
        let nameSeeds = patterns.filter { $0.type == "NAME" }.map(\.text)
        return Self.merge(patterns + nameFindings(text, seeds: [nameSeeds.joined(separator: " ")]))
    }

    // MARK: Strict names (cloud gate only)

    /// Words that start with a capital in headings, job titles and labels; a run made only of these isn't a name.
    static let strictStopwords: Set<String> = [
        "payroll", "specialist", "officer", "analyst", "associate", "assistant", "supervisor", "lead", "manager", "senior",
        "junior", "head", "chief", "director", "hr", "human", "resources", "resource", "generalist", "recruitment", "recruiter",
        "accounting", "accountant", "operations", "customer", "service", "services", "support", "education", "experience",
        "work", "skills", "summary", "professional", "personal", "details", "references", "reference", "trainings", "training",
        "seminars", "seminar", "attended", "bachelor", "science", "technology", "university", "college", "school", "company",
        "corp", "corporation", "inc", "logistics", "address", "date", "birth", "place", "sex", "civil", "status",
        "citizenship", "religion", "government", "numbers", "number", "contact", "emergency", "relationship", "employment",
        "information", "position", "department", "basic", "salary", "monthly", "rate", "expected", "source", "question",
        "sources", "present", "filipino", "single", "married", "male", "female", "mobile", "email", "phone", "tel", "no",
        "january", "february", "march", "april", "may", "june", "july", "august", "september", "october", "november",
        "december", "jan", "feb", "mar", "apr", "jun", "jul", "aug", "sep", "sept", "oct", "nov", "dec", "the", "and",
        "of", "for", "in", "at", "to", "sss", "tin", "philhealth", "pag", "ibig", "philsys", "train", "law", "bir", "form",
        "memo", "memorandum", "offer", "letter", "contract", "resume", "curriculum", "vitae", "applicant", "employee",
        "employer", "pay", "net", "gross", "deductions", "overtime", "withholding", "tax", "period", "id", "hmo",
        "certificate", "file", "files", "page", "pages", "yes", "none", "objective", "career", "achievements", "key",
    ]

    /// Runs of 2–4 Capitalized/ALL-CAPS words and "Surname, First M." forms that aren't only headings or labels.
    /// Deliberately over-redacts: used only for text that leaves the Mac.
    public func strictNameFindings(_ text: String) -> [Finding] {
        let patterns = [
            "\\b[A-ZÑ][A-Za-zÑñ'-]+(?:[ \\t]+(?:[A-ZÑ]\\.|[A-ZÑ][A-Za-zÑñ'-]+)){1,3}\\b",
            "\\b[A-ZÑ][A-Za-zÑñ'-]+,[ \\t]+[A-ZÑ][A-Za-zÑñ'-]+(?:[ \\t]+[A-ZÑ][A-Za-zÑñ'-]+)?(?:[ \\t]+[A-ZÑ]\\.)?",
        ]
        let ns = text as NSString
        var out: [Finding] = []
        for p in patterns {
            guard let re = regex(p) else { continue }
            for m in re.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
                let value = ns.substring(with: m.range)
                if value.contains("[") || value.contains("]") { continue }
                let words = value.lowercased().components(separatedBy: CharacterSet.letters.inverted).filter { $0.count > 1 }
                guard !words.isEmpty, !words.allSatisfy({ Self.strictStopwords.contains($0) }) else { continue }
                out.append(Finding(type: "NAME", label: "name", category: "name", text: value, range: m.range, layer: 2))
            }
        }
        return out
    }

    // MARK: Layer 3 — LLM

    public struct FullResult {
        public var findings: [Finding]
        /// Which provider ran the LLM pass, or nil if it was unavailable.
        public var llmProvider: ProviderKind?
    }

    /// All three layers. The LLM pass runs locally; if Ollama is down it falls back to the cloud endpoint on text
    /// already redacted by layers 1–2. If no LLM is available the fast findings are returned on their own.
    public func detectFull(_ text: String, packs: [String] = GelSettings.shared.activePacks) async -> FullResult {
        let fast = detectFast(text, packs: packs)
        var llm: [Finding] = []
        var provider: ProviderKind?
        let ns = text as NSString
        // Keep each LLM call small; a 4B model is more reliable on short inputs.
        var cursor = 0
        while cursor < ns.length {
            let len = min(2500, ns.length - cursor)
            let piece = ns.substring(with: NSRange(location: cursor, length: len))
            if let (items, p) = try? await llmItems(piece, packs: packs) {
                provider = provider ?? p
                for item in items { llm += Self.locate(item.text, in: text, type: item.type, layer: 3) }
            }
            cursor += len
        }
        return FullResult(findings: Self.merge(fast + llm), llmProvider: provider)
    }

    private struct LLMItem: Decodable { var text: String; var type: String }

    private func llmItems(_ text: String, packs: [String]) async throws -> ([LLMItem], ProviderKind) {
        let system = """
        You find personal data in documents. Return JSON only: {"items":[{"text":"<exact substring>","type":"<TYPE>"}]}.
        TYPE is one of NAME, ADDRESS, SALARY, HEALTH, ID, CONTACT, BIRTHDATE, OTHER.
        Include people's full names, home addresses, salary or pay amounts, medical or health details, ID numbers,
        phone numbers, emails and birth dates. Copy each "text" exactly as it appears. Skip anything already shown as
        a [TOKEN] in square brackets. Do not include company names, job titles or section headings. If none, return {"items":[]}.
        """
        let messages: [ChatMessage] = [.system(system), .user(text)]
        let result = try await ModelRouter.shared.completeJSON(messages) { content in
            try Redactor.cloudSafeWithMapping(content, packs: packs, strict: true)
        }
        let json = Self.extractJSON(result.text)
        struct Wrapper: Decodable { var items: [LLMItem] }
        let items = (try? JSONDecoder().decode(Wrapper.self, from: Data(json.utf8)).items) ?? []
        return (items.filter { $0.text.count >= 3 && !$0.text.contains("[") }, result.provider)
    }

    static func extractJSON(_ s: String) -> String {
        guard let start = s.firstIndex(of: "{"), let end = s.lastIndex(of: "}") else { return "{}" }
        return String(s[start...end])
    }

    static let llmTypeInfo: [String: (label: String, category: String)] = [
        "NAME": ("name", "name"), "ADDRESS": ("home address", "address"), "SALARY": ("salary", "salary"),
        "HEALTH": ("health information", "health"), "ID": ("ID number", "government ID"),
        "CONTACT": ("contact detail", "contact"), "BIRTHDATE": ("date of birth", "date of birth"), "OTHER": ("personal detail", "other"),
    ]

    static func locate(_ needle: String, in text: String, type: String, layer: Int) -> [Finding] {
        let ns = text as NSString
        let info = llmTypeInfo[type.uppercased()] ?? ("personal detail", "other")
        var out: [Finding] = []
        var search = NSRange(location: 0, length: ns.length)
        while true {
            let r = ns.range(of: needle, options: [.caseInsensitive], range: search)
            if r.location == NSNotFound { break }
            out.append(Finding(type: type.uppercased(), label: info.label, category: info.category, text: ns.substring(with: r), range: r, layer: layer))
            let next = r.location + r.length
            search = NSRange(location: next, length: ns.length - next)
        }
        return out
    }

    /// Keeps the longest finding where spans overlap (e.g. a PhilSys number wins over a Pag-IBIG-shaped part of it).
    public static func merge(_ input: [Finding]) -> [Finding] {
        // A government ID inside a longer non-ID span (e.g. an address line that runs into "SSS No: …") stays its own
        // finding; the longer span is cut to end before it, so policies and counts see the ID.
        var findings = input
        let ids = input.filter { $0.category == "government ID" }
        for i in findings.indices where findings[i].category != "government ID" {
            let outer = findings[i].range
            guard let inner = ids.filter({ NSLocationInRange($0.range.location, outer) && $0.range.location > outer.location })
                .min(by: { $0.range.location < $1.range.location }) else { continue }
            var cut = (findings[i].text as NSString).substring(to: inner.range.location - outer.location)
            while let last = cut.unicodeScalars.last, CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ",;:-|")).contains(last) {
                cut.removeLast()
            }
            // Drop a trailing field label such as "SSS No" left at the end of the cut span.
            if let r = cut.range(of: "\\s+(SSS|TIN|PhilHealth|Pag-?IBIG|PhilSys)[A-Za-z .#:]*$", options: [.regularExpression, .caseInsensitive]) {
                cut = String(cut[..<r.lowerBound])
            }
            findings[i].text = cut
            findings[i].range = NSRange(location: outer.location, length: (cut as NSString).length)
        }
        findings.removeAll { $0.range.length < 3 }
        let generic: Set<String> = ["PHONE", "AMOUNT", "NAME", "OTHER"]
        let sorted = findings.sorted { a, b in
            if a.range.length != b.range.length { return a.range.length > b.range.length }
            let ga = generic.contains(a.type), gb = generic.contains(b.type)
            if ga != gb { return !ga }
            return a.layer < b.layer
        }
        var kept: [Finding] = []
        for f in sorted where !kept.contains(where: { NSIntersectionRange($0.range, f.range).length > 0 }) {
            kept.append(f)
        }
        return kept.sorted { $0.range.location < $1.range.location }
    }

    /// "3 government ID numbers, 1 salary, 1 address" — counts by category, for the leak overlay and reports.
    public static func summary(_ findings: [Finding]) -> String {
        let counts = Dictionary(grouping: findings, by: \.category).mapValues(\.count)
        let order = ["government ID", "salary", "bank account", "card", "money", "address", "date of birth", "health", "contact", "name", "other"]
        let parts = counts.sorted { (order.firstIndex(of: $0.key) ?? 99) < (order.firstIndex(of: $1.key) ?? 99) }.map { key, n -> String in
            let noun: String
            switch key {
            case "government ID": noun = n == 1 ? "government ID number" : "government ID numbers"
            case "salary": noun = n == 1 ? "salary" : "salaries"
            case "address": noun = n == 1 ? "address" : "addresses"
            case "bank account": noun = n == 1 ? "bank account" : "bank accounts"
            case "card": noun = n == 1 ? "card number" : "card numbers"
            case "money": noun = n == 1 ? "money amount" : "money amounts"
            case "date of birth": noun = n == 1 ? "birth date" : "birth dates"
            case "contact": noun = n == 1 ? "contact detail" : "contact details"
            case "name": noun = n == 1 ? "name" : "names"
            case "health": noun = "health detail" + (n == 1 ? "" : "s")
            default: noun = "personal detail" + (n == 1 ? "" : "s")
            }
            return "\(n) \(noun)"
        }
        return parts.joined(separator: ", ")
    }
}
