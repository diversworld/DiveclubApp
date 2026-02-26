//
//  InstructorStudent.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 08.02.26.
//


import Foundation

struct InstructorStudent: Codable, Identifiable {

    // MARK: - Core
    let id: Int

    // MARK: - Fields
    let medicalOk: Bool?
    let published: Bool?
    let sorting: Int?
    let tstamp: Int?

    let firstname: String?
    let lastname: String?
    let email: String?
    let phone: String?
    let notes: String?

    let start: String?
    let stop: String?

    let allowLogin: Bool?
    let gender: String?

    let street: String?
    let postal: String?
    let city: String?
    let state: String?
    let country: String?
    let language: String?
    let mobile: String?
    let username: String?

    /// Normalisiert immer zu [Int], obwohl Backend evtl. String/Array liefert.
    let memberGroups: [Int]

    let memberId: Int?

    /// ✅ Backend liefert Unix Timestamp (Sekunden)
    let dateOfBirth: Int?

    // MARK: - CodingKeys
    enum CodingKeys: String, CodingKey {
        case id
        case medicalOk = "medical_ok"
        case published, sorting, tstamp

        case firstname, lastname, email, phone, notes
        case start, stop
        case allowLogin
        case gender

        case street, postal, city, state, country, language, mobile, username

        // Achtung: Backend liefert bei dir teils memberGroups (camelCase).
        // Wir decodieren das via custom init, daher bleibt der Key hier optional.
        case memberGroups        // "memberGroups"
        case memberGroupsSnake = "member_groups"

        case memberId
        case dateOfBirth
    }

    // MARK: - Custom Decoding
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id = try c.decode(Int.self, forKey: .id)
        medicalOk = try c.decodeIfPresent(Bool.self, forKey: .medicalOk)
        published = try c.decodeIfPresent(Bool.self, forKey: .published)
        sorting = try c.decodeIfPresent(Int.self, forKey: .sorting)
        tstamp = try c.decodeIfPresent(Int.self, forKey: .tstamp)

        firstname = try c.decodeIfPresent(String.self, forKey: .firstname)
        lastname  = try c.decodeIfPresent(String.self, forKey: .lastname)
        email     = try c.decodeIfPresent(String.self, forKey: .email)
        phone     = try c.decodeIfPresent(String.self, forKey: .phone)
        notes     = try c.decodeIfPresent(String.self, forKey: .notes)

        start = try c.decodeIfPresent(String.self, forKey: .start)
        stop  = try c.decodeIfPresent(String.self, forKey: .stop)

        allowLogin = try c.decodeIfPresent(Bool.self, forKey: .allowLogin)
        gender     = try c.decodeIfPresent(String.self, forKey: .gender)

        street   = try c.decodeIfPresent(String.self, forKey: .street)
        postal   = try c.decodeIfPresent(String.self, forKey: .postal)
        city     = try c.decodeIfPresent(String.self, forKey: .city)
        state    = try c.decodeIfPresent(String.self, forKey: .state)
        country  = try c.decodeIfPresent(String.self, forKey: .country)
        language = try c.decodeIfPresent(String.self, forKey: .language)
        mobile   = try c.decodeIfPresent(String.self, forKey: .mobile)
        username = try c.decodeIfPresent(String.self, forKey: .username)

        memberId = try c.decodeIfPresent(Int.self, forKey: .memberId)

        // ✅ Backend liefert dateOfBirth mal als String (ggf. leer), mal als Zahl
        if let strVal = try? c.decodeIfPresent(String.self, forKey: .dateOfBirth) {
            let trimmed = strVal.trimmingCharacters(in: .whitespacesAndNewlines)
            dateOfBirth = Int(trimmed)
        } else if let intVal = try? c.decodeIfPresent(Int.self, forKey: .dateOfBirth) {
            dateOfBirth = intVal
        } else {
            dateOfBirth = nil
        }

        // ✅ memberGroups tolerant (memberGroups oder member_groups, Array oder String oder PHP-serialized)
        memberGroups = Self.decodeMemberGroups(from: c)
    }

    // MARK: - Custom Encoding (optional, aber komplett)
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)

        try c.encode(id, forKey: .id)
        try c.encodeIfPresent(medicalOk, forKey: .medicalOk)
        try c.encodeIfPresent(published, forKey: .published)
        try c.encodeIfPresent(sorting, forKey: .sorting)
        try c.encodeIfPresent(tstamp, forKey: .tstamp)

        try c.encodeIfPresent(firstname, forKey: .firstname)
        try c.encodeIfPresent(lastname, forKey: .lastname)
        try c.encodeIfPresent(email, forKey: .email)
        try c.encodeIfPresent(phone, forKey: .phone)
        try c.encodeIfPresent(notes, forKey: .notes)

        try c.encodeIfPresent(start, forKey: .start)
        try c.encodeIfPresent(stop, forKey: .stop)

        try c.encodeIfPresent(allowLogin, forKey: .allowLogin)
        try c.encodeIfPresent(gender, forKey: .gender)

        try c.encodeIfPresent(street, forKey: .street)
        try c.encodeIfPresent(postal, forKey: .postal)
        try c.encodeIfPresent(city, forKey: .city)
        try c.encodeIfPresent(state, forKey: .state)
        try c.encodeIfPresent(country, forKey: .country)
        try c.encodeIfPresent(language, forKey: .language)
        try c.encodeIfPresent(mobile, forKey: .mobile)
        try c.encodeIfPresent(username, forKey: .username)

        // Wir encoden in camelCase (passt zu deinem aktuellen Backend-Sample).
        try c.encode(memberGroups, forKey: .memberGroups)

        try c.encodeIfPresent(memberId, forKey: .memberId)
        if let ts = dateOfBirth {
            try c.encode(String(ts), forKey: .dateOfBirth)
        }
    }

    // MARK: - Convenience

    var fullName: String {
        let name = "\(firstname ?? "") \(lastname ?? "")"
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Unbekannt" : name
    }

    var dateOfBirthDate: Date? {
        guard let ts = dateOfBirth else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(ts))
    }

    /// Locale-aware Kurzformat (z. B. 12.09.1986)
    var dateOfBirthFormatted: String? {
        guard let date = dateOfBirthDate else { return nil }
        return DateFormatter.dobFormatter.string(from: date)
    }

    // MARK: - Helpers

    private static func decodeMemberGroups(from c: KeyedDecodingContainer<CodingKeys>) -> [Int] {
        // Wir probieren zuerst camelCase, dann snake_case.
        // 1) [Int]
        if let ints = (try? c.decodeIfPresent([Int].self, forKey: .memberGroups)) ?? nil {
            return ints
        }
        if let ints = (try? c.decodeIfPresent([Int].self, forKey: .memberGroupsSnake)) ?? nil {
            return ints
        }

        // 2) [String]
        if let strings = (try? c.decodeIfPresent([String].self, forKey: .memberGroups)) ?? nil {
            return strings.compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        }
        if let strings = (try? c.decodeIfPresent([String].self, forKey: .memberGroupsSnake)) ?? nil {
            return strings.compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        }

        // 3) String (CSV / JSON-string / PHP-serialized)
        if let s = (try? c.decodeIfPresent(String.self, forKey: .memberGroups)) ?? nil {
            return parseGroupsString(s)
        }
        if let s = (try? c.decodeIfPresent(String.self, forKey: .memberGroupsSnake)) ?? nil {
            return parseGroupsString(s)
        }

        // 4) null / fehlt
        return []
    }

    private static func parseGroupsString(_ raw: String) -> [Int] {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return [] }

        // a) JSON-Array als String: "[1,2]"
        if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
            let inner = trimmed.dropFirst().dropLast()
            return inner
                .split(separator: ",")
                .compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        }

        // b) PHP-serialized array: a:1:{i:0;s:1:"2";}
        // Wir extrahieren alle Zahlen in Anführungszeichen (oder auch ohne) und nehmen sie als IDs.
        if trimmed.contains("a:") && trimmed.contains("{") && trimmed.contains("}") {
            // Beispiel: ... s:1:"2" ...
            let matches = trimmed.matches(for: #""(\d+)""#)
            if !matches.isEmpty {
                return matches.compactMap { Int($0) }
            }

            // Fallback: alle reinen Ziffernfolgen extrahieren
            let nums = trimmed.matches(for: #"\b\d+\b"#)
            // Da PHP-serialized auch Längenangaben enthält (a:1, i:0, s:1, ...),
            // filtern wir sehr kleine typische Meta-Zahlen raus und nehmen plausiblere Werte.
            // (Nicht perfekt, aber verhindert oft [1,0,1,2].)
            let filtered = nums.compactMap(Int.init).filter { $0 > 1 }
            return Array(Set(filtered)).sorted()
        }

        // c) CSV/Whitespace: "1,2,3" / "1 2 3" / "1;2;3"
        return trimmed
            .split(whereSeparator: { $0 == "," || $0 == ";" || $0 == " " })
            .compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
    }
}

// MARK: - DateFormatter helper
private extension DateFormatter {
    static let dobFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        df.locale = .current
        return df
    }()
}

// MARK: - Regex helper
private extension String {
    func matches(for pattern: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let ns = self as NSString
            let range = NSRange(location: 0, length: ns.length)
            return regex.matches(in: self, options: [], range: range).map { m in
                ns.substring(with: m.range(at: 1))
            }
        } catch {
            return []
        }
    }
}

