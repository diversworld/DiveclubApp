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

    /// HTML -> Plain Text (mit Absätzen + Bulletpoints)
    var htmlToPlainText: String {
        // 1) erst Entities decodieren (du hast decodedEntities in String+Entities.swift)
        var s = self.decodedEntities

        // 2) Zeilenumbrüche/Block-Struktur grob abbilden
        // Paragraphs / breaks
        s = s.replacingOccurrences(of: "(?i)<br\\s*/?>", with: "\n", options: .regularExpression)
        s = s.replacingOccurrences(of: "(?i)</p\\s*>", with: "\n\n", options: .regularExpression)
        s = s.replacingOccurrences(of: "(?i)<p\\b[^>]*>", with: "", options: .regularExpression)

        // Headings -> extra Abstand
        s = s.replacingOccurrences(of: "(?i)</h[1-6]\\s*>", with: "\n\n", options: .regularExpression)
        s = s.replacingOccurrences(of: "(?i)<h[1-6]\\b[^>]*>", with: "\n", options: .regularExpression)

        // Divs -> nur Abstand, Inhalt bleibt
        s = s.replacingOccurrences(of: "(?i)</div\\s*>", with: "\n", options: .regularExpression)
        s = s.replacingOccurrences(of: "(?i)<div\\b[^>]*>", with: "", options: .regularExpression)

        // Lists:
        // UL bullets
        s = s.replacingOccurrences(of: "(?i)</ul\\s*>", with: "\n", options: .regularExpression)
        s = s.replacingOccurrences(of: "(?i)<ul\\b[^>]*>", with: "\n", options: .regularExpression)

        // OL numbering (heuristisch):
        // Wir markieren <li> erstmal, nummerieren später pro Block.
        s = s.replacingOccurrences(of: "(?i)</ol\\s*>", with: "\n", options: .regularExpression)
        s = s.replacingOccurrences(of: "(?i)<ol\\b[^>]*>", with: "\n[[OL_START]]\n", options: .regularExpression)

        // li
        s = s.replacingOccurrences(of: "(?i)</li\\s*>", with: "\n", options: .regularExpression)
        s = s.replacingOccurrences(of: "(?i)<li\\b[^>]*>", with: "• ", options: .regularExpression)

        // 3) Alle restlichen Tags weg
        s = s.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

        // 4) OL Nummerierung nachträglich erzeugen
        // Jede [[OL_START]] Sektion: ersetze die dortigen "• " Zeilen durch "1. ", "2. " ...
        s = applySimpleOrderedListNumbering(s)

        // 5) Whitespace aufräumen
        s = s.replacingOccurrences(of: "\r\n", with: "\n")
        s = s.replacingOccurrences(of: "\r", with: "\n")

        // Mehrfach-Leerzeilen reduzieren
        s = s.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)

        // trailing spaces je Zeile entfernen
        s = s
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return s
    }

    /// Kurzer Teaser aus HTML (für Listen/Karten)
    func htmlSummary(maxChars: Int = 220) -> String {
        let plain = self.htmlToPlainText
        if plain.count <= maxChars { return plain }

        // schöner cut: bis zum letzten Leerzeichen
        let idx = plain.index(plain.startIndex, offsetBy: maxChars)
        let prefix = String(plain[..<idx])
        if let lastSpace = prefix.lastIndex(of: " ") {
            return String(prefix[..<lastSpace]).trimmingCharacters(in: .whitespacesAndNewlines) + " …"
        }
        return prefix.trimmingCharacters(in: .whitespacesAndNewlines) + " …"
    }

    // MARK: - helper

    private func applySimpleOrderedListNumbering(_ input: String) -> String {
        // Wir splitten in Blöcke an [[OL_START]]
        let parts = input.components(separatedBy: "[[OL_START]]")
        guard parts.count > 1 else { return input }

        var result = parts[0]
        for i in 1..<parts.count {
            var block = parts[i]

            // Nummeriere Zeilen, die mit "• " starten, bis zum nächsten Leerblock (oder Blockende)
            var lines = block.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
            var n = 1
            for idx in 0..<lines.count {
                let line = lines[idx].trimmingCharacters(in: .whitespaces)
                if line.hasPrefix("• ") {
                    // nur in diesem OL-Block nummerieren
                    let content = line.dropFirst(2) // "• "
                    lines[idx] = "\(n). \(content)"
                    n += 1
                }
            }

            block = lines.joined(separator: "\n")
            result += block
        }
        return result
    }
}
