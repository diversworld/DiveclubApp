//
//  String+HTML.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 08.02.26.
//

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import Foundation

extension String {

    var htmlToPlainText: String {
        if isEmpty { return self }

        var s = self

        // 1) harte Zeilenumbrüche / Absatzende
        let blockBreaks = [
            "(?i)<br\\s*/?>",
            "(?i)</p\\s*>",
            "(?i)</div\\s*>",
            "(?i)</h[1-6]\\s*>",
            "(?i)</tr\\s*>",
            "(?i)</ul\\s*>",
            "(?i)</ol\\s*>"
        ]
        for p in blockBreaks {
            s = s.replacingRegex(p, with: "\n")
        }

        // 2) Listenanfänge auch auf neue Zeile
        s = s.replacingRegex("(?i)<ul\\b[^>]*>", with: "\n")
        s = s.replacingRegex("(?i)<ol\\b[^>]*>", with: "\n")

        // 3) List items: immer in neue Zeile
        s = s.replacingRegex("(?i)<li\\b[^>]*>", with: "\n• ")
        s = s.replacingRegex("(?i)</li\\s*>", with: "\n")

        // 4) restliche Tags entfernen
        s = s.replacingRegex("<[^>]+>", with: "")

        // 5) Entities decoden
        s = s.decodingHTMLEntitiesFoundationOnly()

        // 6) Normalisieren (Leerzeichen/Zeilen)
        s = s.replacingRegex("\r", with: "")
        s = s.replacingRegex("[ \\t\\f\\v]+", with: " ")
        s = s.replacingRegex("[ ]*\\n[ ]*", with: "\n")   // spaces um newlines weg
        s = s.replacingRegex("\\n{3,}", with: "\n\n")     // max 2 newlines
        s = s.replacingRegex("\\n•\\s*\\n", with: "\n")   // leere bullets raus

        // 7) Bullet-Kanten glätten: wenn direkt nach Text ein Bullet kommt -> Absatz
        s = s.replacingRegex("([^\\n])\\n•", with: "$1\n\n•")

        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Entity decoding (Foundation-only)

    private func decodingHTMLEntitiesFoundationOnly() -> String {
        if isEmpty { return self }
        var out = self

        let named: [String: String] = [
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&apos;": "'",
            "&#39;": "'",
            "&#34;": "\"",
            "&nbsp;": " "
        ]
        for (k, v) in named {
            out = out.replacingOccurrences(of: k, with: v)
        }

        out = out.replacingRegexMatches("&#(\\d+);") { full, groups in
            guard let codeStr = groups.first, let code = Int(codeStr),
                  let scalar = UnicodeScalar(code) else { return full }
            return String(scalar)
        }

        out = out.replacingRegexMatches("&#x([0-9a-fA-F]+);") { full, groups in
            guard let hex = groups.first, let code = Int(hex, radix: 16),
                  let scalar = UnicodeScalar(code) else { return full }
            return String(scalar)
        }

        return out
    }
}

// MARK: - Regex helpers

private extension String {

    func replacingRegex(_ pattern: String, with replacement: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return self }
        let range = NSRange(startIndex..<endIndex, in: self)
        return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: replacement)
    }

    func replacingRegexMatches(
        _ pattern: String,
        replacer: (_ fullMatch: String, _ captureGroups: [String]) -> String
    ) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return self }

        let ns = self as NSString
        let matches = regex.matches(in: self, options: [], range: NSRange(location: 0, length: ns.length))
        if matches.isEmpty { return self }

        var result = self
        for m in matches.reversed() {
            let full = ns.substring(with: m.range(at: 0))
            var groups: [String] = []
            if m.numberOfRanges > 1 {
                for i in 1..<m.numberOfRanges {
                    let r = m.range(at: i)
                    groups.append(r.location != NSNotFound ? ns.substring(with: r) : "")
                }
            }
            let replacement = replacer(full, groups)
            result = (result as NSString).replacingCharacters(in: m.range(at: 0), with: replacement)
        }
        return result
    }
}
