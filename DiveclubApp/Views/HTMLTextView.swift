//
//  HTMLTextView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 09.02.26.
//


import SwiftUI
import UIKit

struct HTMLTextView: View {
    let html: String
    var textStyle: UIFont.TextStyle = .body

    @State private var rendered: AttributedString = AttributedString("")

    var body: some View {
        Text(rendered)
            // nur neu rendern, wenn sich html oder style ändert
            .task(id: renderKey) {
                let htmlInput = html
                let style = textStyle

                // Heavy work off-main
                let attributed = await Task.detached(priority: .userInitiated) {
                    Self.makeAttributedHTML(htmlInput, textStyle: style)
                }.value

                // Convert to SwiftUI AttributedString on main
                await MainActor.run {
                    self.rendered = (try? AttributedString(attributed, including: \.uiKit)) ?? AttributedString(htmlInput)
                }
            }
    }

    private var renderKey: String {
        "\(textStyle.rawValue)::\(html.hashValue)"
    }

    // MARK: - Rendering

    static func makeAttributedHTML(_ html: String, textStyle: UIFont.TextStyle) -> NSAttributedString {
        // 1) Entities vorher dekodieren (&#40; usw.)
        //    (decodedEntities kommt aus deiner String+Entities.swift)
        let decoded = html.decodedEntities

        // 2) CSS mit Dynamic Type Größen
        let baseFont = UIFont.preferredFont(forTextStyle: textStyle)
        let bodySize = baseFont.pointSize
        let h3Size = UIFont.preferredFont(forTextStyle: .headline).pointSize

        // Einrückung und Abstände für Listen/Absätze wie im Web
        let css = """
        <style>
        body {
            font-family: -apple-system, system-ui;
            font-size: \(bodySize)px;
            line-height: 1.35;
        }
        p { margin: 0 0 10px 0; }
        h3 {
            font-size: \(h3Size)px;
            font-weight: 600;
            margin: 14px 0 8px 0;
        }
        ul, ol { margin: 0 0 10px 0; padding-left: 20px; }
        li { margin: 0 0 6px 0; }
        </style>
        """

        let wrappedHTML = """
        <html>
          <head>\(css)</head>
          <body>\(decoded)</body>
        </html>
        """

        guard let data = wrappedHTML.data(using: .utf8) else {
            return NSAttributedString(string: decoded)
        }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        let attr = (try? NSMutableAttributedString(data: data, options: options, documentAttributes: nil))
            ?? NSMutableAttributedString(string: decoded)

        // 3) HTML-Farben entfernen, damit SwiftUI .foregroundStyle sauber greift
        //    (sonst kommen z.B. schwarze Texte trotz .secondary)
        attr.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: attr.length)) { value, range, _ in
            if value != nil { attr.removeAttribute(.foregroundColor, range: range) }
        }
        attr.enumerateAttribute(.backgroundColor, in: NSRange(location: 0, length: attr.length)) { value, range, _ in
            if value != nil { attr.removeAttribute(.backgroundColor, range: range) }
        }

        // 4) Fallback: wenn HTML keine Fonts sauber setzt, setzen wir Default-Font nur dort,
        //    wo kein Font existiert. (Überschriften behalten ihre Größe/Fettung)
        attr.enumerateAttribute(.font, in: NSRange(location: 0, length: attr.length)) { value, range, _ in
            if value == nil {
                attr.addAttribute(.font, value: baseFont, range: range)
            }
        }

        return attr
    }
}
