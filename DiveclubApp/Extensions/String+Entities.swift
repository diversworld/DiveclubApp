//
//  String+Entities.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 08.02.26.
//

import Foundation

private final class EntityDecodeCache {
    static let shared = EntityDecodeCache()
    private let cache = NSCache<NSString, NSString>()

    private init() {
        cache.countLimit = 2000
    }

    func get(_ key: String) -> String? {
        cache.object(forKey: key as NSString) as String?
    }

    func set(_ value: String, for key: String) {
        cache.setObject(value as NSString, forKey: key as NSString)
    }
}

extension String {

    /// ✅ Schnell + SwiftUI-sicher: decodiert gängige HTML Entities & numerische Entities
    /// ohne NSAttributedString/WebKit. Mit Cache.
    var decodedEntities: String {
        if isEmpty { return self }
        if let cached = EntityDecodeCache.shared.get(self) { return cached }

        var s = self

        // Häufige Named entities
        s = s
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&#34;", with: "\"")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&nbsp;", with: " ")

        // Dezimal: &#40;
        s = s.replacingMatches(pattern: #"&#(\d+);"#) { captures, original in
            guard let num = Int(captures[0]),
                  let scalar = UnicodeScalar(num) else { return original }
            return String(Character(scalar))
        }

        // Hex: &#x27;
        s = s.replacingMatches(pattern: #"&#x([0-9A-Fa-f]+);"#) { captures, original in
            guard let num = Int(captures[0], radix: 16),
                  let scalar = UnicodeScalar(num) else { return original }
            return String(Character(scalar))
        }

        // Deine Beispiele enthalten auch "\/" in JSON (nur Escaping). Das ist im Swift-String
        // normalerweise schon "/", aber falls doch noch vorhanden:
        s = s.replacingOccurrences(of: #"\/"#, with: "/")

        EntityDecodeCache.shared.set(s, for: self)
        return s
    }
}

// MARK: - Regex helper
private extension String {
    func replacingMatches(
        pattern: String,
        using transform: (_ captures: [String], _ original: String) -> String
    ) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return self }
        let ns = self as NSString
        let range = NSRange(location: 0, length: ns.length)

        var result = self
        let matches = regex.matches(in: self, range: range).reversed() // rückwärts für stabile ranges

        for m in matches {
            let original = ns.substring(with: m.range)
            var captures: [String] = []
            if m.numberOfRanges > 1 {
                for i in 1..<m.numberOfRanges {
                    let r = m.range(at: i)
                    if r.location != NSNotFound {
                        captures.append(ns.substring(with: r))
                    }
                }
            }
            let replacement = transform(captures, original)
            if let rSwift = Range(m.range, in: result) {
                result.replaceSubrange(rSwift, with: replacement)
            }
        }
        return result
    }
}
