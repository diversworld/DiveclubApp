//
//  HTMLTextView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 09.02.26.
//

import SwiftUI
import UIKit

/// HTML als nicht-scrollender UITextView (List-tauglich)
struct HTMLTextView: UIViewRepresentable {
    let html: String
    var textStyle: UIFont.TextStyle = .body

    /// nil = keine Begrenzung, sonst maximale Zeilenanzahl
    var lineLimit: Int? = nil

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.isEditable = false
        tv.isSelectable = true
        tv.isScrollEnabled = false   // ✅ wichtig in List: keine Scroll-Hölle
        tv.backgroundColor = .clear
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        tv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // wichtig für sauberes Layout in SwiftUI
        tv.translatesAutoresizingMaskIntoConstraints = false

        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = makeAttributedHTML(html, textStyle: textStyle)

        // ✅ LINE LIMIT (funktioniert nur über UIKit, nicht über SwiftUI .lineLimit)
        if let limit = lineLimit, limit > 0 {
            uiView.textContainer.maximumNumberOfLines = limit
            uiView.textContainer.lineBreakMode = .byTruncatingTail
        } else {
            uiView.textContainer.maximumNumberOfLines = 0
            uiView.textContainer.lineBreakMode = .byWordWrapping
        }

        // Layout-Refresh erzwingen (damit die Höhe nach Toggle sauber neu berechnet wird)
        uiView.invalidateIntrinsicContentSize()
        uiView.setNeedsLayout()
    }

    private func makeAttributedHTML(_ html: String, textStyle: UIFont.TextStyle) -> NSAttributedString {
        let data = Data(html.utf8)

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        let base = (try? NSMutableAttributedString(data: data, options: options, documentAttributes: nil))
            ?? NSMutableAttributedString(string: html)

        // ✅ Standardfont sauber setzen (auch für Listen/Überschriften)
        let font = UIFont.preferredFont(forTextStyle: textStyle)
        base.addAttribute(.font, value: font, range: NSRange(location: 0, length: base.length))

        return base
    }
}
