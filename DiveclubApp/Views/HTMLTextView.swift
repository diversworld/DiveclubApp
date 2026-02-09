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

    @State private var attributed: NSAttributedString = NSAttributedString(string: "")

    var body: some View {
        Text(AttributedString(attributed))
            .task {
                await MainActor.run {
                    attributed = Self.makeAttributedHTML(html, textStyle: textStyle)
                }
            }
    }

    // Kein @MainActor hier nötig, wir rufen es sowieso auf MainActor auf
    static func makeAttributedHTML(_ html: String, textStyle: UIFont.TextStyle) -> NSAttributedString {
        let data = Data(html.utf8)

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        let attr = (try? NSAttributedString(data: data, options: options, documentAttributes: nil))
            ?? NSAttributedString(string: html)

        // Optional: Standard-Font setzen
        let font = UIFont.preferredFont(forTextStyle: textStyle)
        let mutable = NSMutableAttributedString(attributedString: attr)
        mutable.addAttributes([.font: font], range: NSRange(location: 0, length: mutable.length))
        return mutable
    }
}
