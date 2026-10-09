import Foundation

/// Type-aware fake values for the "Replace with dummy data" redaction mode (R5, D-073).
/// Every fake is random and never derived from the original, so the output can't be reversed; `replacements(for:)`
/// keeps one fake per distinct value, so a document stays consistent ("Liza Velasco" is the same fake everywhere).
public enum DummyData {
    /// Tagalog word-names: plausible on a Philippine form, clearly fictional, and none of them appear in demo-data.
    static let firstNames = ["Alon", "Amihan", "Bituin", "Dakila", "Diwa", "Hiraya", "Lakan", "Ligaya", "Makisig", "Marikit",
                             "Mayumi", "Sinag", "Tala", "Bayani", "Luntian", "Dalisay"]
    static let lastNames = ["Halimbawa", "Katibayan", "Pagsubok", "Maligaya", "Sagisag", "Tanglaw", "Bagwis", "Marilag",
                            "Lualhati", "Magiting", "Tagumpay", "Pamana", "Liwanag", "Kalinaw"]
    static let streets = ["Halimbawa St.", "Sagisag Ave.", "Tanglaw Rd.", "Pamana Drive", "Liwanag Ext."]
    static let barangays = ["Brgy. Katibayan", "Brgy. Maligaya", "Brgy. Lualhati", "Brgy. Tagumpay"]
    static let cities = ["Lungsod ng Pagsubok", "Bayan ng Halimbawa", "Kalinaw City", "Marilag City"]
    static let lorem = ("lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor incididunt ut labore "
                        + "et dolore magna aliqua enim ad minim veniam quis nostrud exercitation").split(separator: " ").map(String.init)
    static let months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October",
                         "November", "December"]

    /// One fake per distinct value (case-insensitive), assigned in reading order. Pass the previous map to keep
    /// earlier fakes when findings are added later (the review sheet's "Add something Gel missed").
    public static func replacements(for findings: [Finding], existing: [String: String] = [:]) -> [String: String] {
        var map = existing
        var rng = SystemRandomNumberGenerator()
        for f in findings.sorted(by: { $0.range.location < $1.range.location }) {
            let key = f.text.lowercased()
            if map[key] == nil { map[key] = fake(for: f, using: &rng) }
        }
        return map
    }

    /// A fake of the same kind and roughly the same shape as `finding.text`.
    public static func fake<R: RandomNumberGenerator>(for finding: Finding, using rng: inout R) -> String {
        let original = finding.text
        let type = finding.type.uppercased()
        switch (type, finding.category) {
        case ("NAME", _), (_, "name"):
            return name(like: original, using: &rng)
        case ("EMAIL", _):
            return "\(firstNames.randomElement(using: &rng)!).\(lastNames.randomElement(using: &rng)!)@example.com".lowercased()
        case ("PHONE", _), ("GCASH", _):
            return sameShape(original, keepLeadingDigits: 2, using: &rng)
        case (_, "government ID"), (_, "bank account"), (_, "card"), ("ID", _):
            return sameShape(original, using: &rng)
        case (_, "salary"), (_, "money"):
            return amount(like: original, using: &rng)
        case (_, "date of birth"), ("DATE", _), ("DOB", _), ("BIRTHDATE", _):
            return date(like: original, using: &rng)
        case (_, "address"):
            let zip = Int.random(in: 1000...9999, using: &rng)
            return "\(Int.random(in: 1...999, using: &rng)) \(streets.randomElement(using: &rng)!), \(barangays.randomElement(using: &rng)!), \(cities.randomElement(using: &rng)!) \(zip)"
        default:
            return loremLike(original, using: &rng)
        }
    }

    static func isAllCaps(_ s: String) -> Bool {
        s == s.uppercased() && s.rangeOfCharacter(from: .letters) != nil
    }

    /// "Liza T. Buenaventura" → "Mayumi K. Tanglaw"; "VELASCO, CARLO" → "SAGISAG, DAKILA"; keeps case and comma order.
    static func name<R: RandomNumberGenerator>(like original: String, using rng: inout R) -> String {
        let first = firstNames.randomElement(using: &rng)!
        let last = lastNames.randomElement(using: &rng)!
        let initial = String("ABDGHKLMNPRST".randomElement(using: &rng)!)
        let words = original.split(whereSeparator: { $0 == " " || $0 == "\t" }).count
        var out: String
        if original.contains(",") {
            out = words >= 3 ? "\(last), \(first) \(initial)." : "\(last), \(first)"
        } else if words >= 3 {
            out = "\(first) \(initial). \(last)"
        } else if words == 1 {
            out = last
        } else {
            out = "\(first) \(last)"
        }
        return isAllCaps(original) ? out.uppercased() : out
    }

    /// Keeps separators and letter/digit positions, randomizes the characters: "04-4989449-2" → "71-2048315-9".
    static func sameShape<R: RandomNumberGenerator>(_ original: String, keepLeadingDigits: Int = 0, using rng: inout R) -> String {
        var out = ""
        var digitsSeen = 0
        for ch in original {
            if ch.isNumber {
                digitsSeen += 1
                out.append(digitsSeen <= keepLeadingDigits ? ch : Character(String(Int.random(in: 0...9, using: &rng))))
            } else if ch.isLetter {
                let letter = Character(String("ABCDEFGHJKLMNPRSTUVWXYZ".randomElement(using: &rng)!))
                out.append(ch.isUppercase ? letter : Character(letter.lowercased()))
            } else {
                out.append(ch)
            }
        }
        return out
    }

    /// "₱45,000.00" → "₱31,500.00"; "P18.000.00" (OCR style) → "P27.000.00"; keeps the currency prefix and decimals.
    static func amount<R: RandomNumberGenerator>(like original: String, using rng: inout R) -> String {
        let prefix = String(original.prefix { !$0.isNumber })
        let digits = original.drop { !$0.isNumber }
        let hasDecimals = digits.range(of: "[.,]\\d{2}$", options: .regularExpression) != nil
        let dottedThousands = digits.range(of: "^\\d{1,3}(\\.\\d{3})+", options: .regularExpression) != nil
        let value = Int.random(in: 12...95, using: &rng) * 1000 + Int.random(in: 0...1) * 500
        let thousands = String(value / 1000)
        let rest = String(format: "%03d", value % 1000)
        let sep = dottedThousands ? "." : ","
        let dec = hasDecimals ? (dottedThousands ? ",00" : ".00") : ""
        return prefix + thousands + sep + rest + dec
    }

    /// A random date in the same written form as the original.
    static func date<R: RandomNumberGenerator>(like original: String, using rng: inout R) -> String {
        let year = Int.random(in: 1965...2004, using: &rng)
        let month = Int.random(in: 1...12, using: &rng)
        let day = Int.random(in: 1...28, using: &rng)
        let two = { (n: Int) in String(format: "%02d", n) }
        if original.range(of: "^\\d{4}-\\d{2}-\\d{2}$", options: .regularExpression) != nil {
            return "\(year)-\(two(month))-\(two(day))"
        }
        if let m = original.range(of: "^\\d{1,2}([/-])\\d{1,2}[/-](\\d{2,4})$", options: .regularExpression) {
            let sep = original.contains("/") ? "/" : "-"
            let shortYear = original[m].split(whereSeparator: { $0 == "/" || $0 == "-" }).last?.count == 2
            return "\(two(month))\(sep)\(two(day))\(sep)\(shortYear ? two(year % 100) : String(year))"
        }
        let monthName = months[month - 1]
        if let firstScalar = original.unicodeScalars.first, CharacterSet.decimalDigits.contains(firstScalar) {
            return "\(day) \(monthName) \(year)"
        }
        return "\(monthName) \(day), \(year)"
    }

    /// Lorem words of about the original's length; capitalized like the original.
    static func loremLike<R: RandomNumberGenerator>(_ original: String, using rng: inout R) -> String {
        var out = ""
        var i = Int.random(in: 0..<lorem.count, using: &rng)
        while out.count < max(original.count, 4) {
            out += (out.isEmpty ? "" : " ") + lorem[i % lorem.count]
            i += 1
        }
        if let first = out.first { out = first.uppercased() + out.dropFirst() }
        return isAllCaps(original) ? out.uppercased() : out
    }
}
