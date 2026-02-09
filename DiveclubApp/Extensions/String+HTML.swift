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

extension String {
    /// Decodiert HTML Entities wie &#40; &#41; &amp; etc.
    /// Beispiel: "A &#40;B&#41;" -> "A (B)"
    var decodedHTMLEntities: String {
        guard let data = data(using: .utf8) else { return self }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        let attributed = try? NSAttributedString(
            data: data,
            options: options,
            documentAttributes: nil
        )

        return attributed?.string ?? self
    }
}
