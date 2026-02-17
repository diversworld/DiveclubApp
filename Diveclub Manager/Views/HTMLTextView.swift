//
//  HTMLTextView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 09.02.26.
//

import SwiftUI
import UIKit

// MARK: - Cache

final class HTMLAttributedStringCache {
    static let shared = HTMLAttributedStringCache()
    private let cache = NSCache<NSString, NSAttributedString>()

    private init() {
        cache.countLimit = 300
    }

    func get(_ key: String) -> NSAttributedString? {
        cache.object(forKey: key as NSString)
    }

    func set(_ value: NSAttributedString, for key: String) {
        cache.setObject(value, forKey: key as NSString)
    }
}

// MARK: - View

struct HTMLTextView: UIViewRepresentable {
    let html: String
    var textStyle: UIFont.TextStyle = .body
    var lineLimit: Int? = nil

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.isEditable = false
        tv.isSelectable = true
        tv.isScrollEnabled = false
        tv.backgroundColor = .clear
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        tv.textContainer.widthTracksTextView = true
        tv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        let key = cacheKey(html: html, style: textStyle, lineLimit: lineLimit)

        // ✅ nur updaten, wenn sich wirklich etwas geändert hat
        if context.coordinator.lastKey != key {
            context.coordinator.lastKey = key

            if let cached = HTMLAttributedStringCache.shared.get(key) {
                uiView.attributedText = cached
            } else {
                let attr = makeAttributedHTML(html, textStyle: textStyle)
                HTMLAttributedStringCache.shared.set(attr, for: key)
                uiView.attributedText = attr
            }
        }

        // ✅ LineLimit nur setzen, wenn sich geändert hat
        let newLimit = (lineLimit ?? 0)
        if context.coordinator.lastLineLimit != newLimit {
            context.coordinator.lastLineLimit = newLimit

            if let limit = lineLimit, limit > 0 {
                uiView.textContainer.maximumNumberOfLines = limit
                uiView.textContainer.lineBreakMode = .byTruncatingTail
            } else {
                uiView.textContainer.maximumNumberOfLines = 0
                uiView.textContainer.lineBreakMode = .byWordWrapping
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var lastKey: String?
        var lastLineLimit: Int?
    }

    private func cacheKey(html: String, style: UIFont.TextStyle, lineLimit: Int?) -> String {
        "\(style.rawValue)|\(lineLimit ?? -1)|\(html.hashValue)"
    }

    private func makeAttributedHTML(_ html: String, textStyle: UIFont.TextStyle) -> NSAttributedString {
        let data = Data(html.utf8)

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        let base = (try? NSMutableAttributedString(data: data, options: options, documentAttributes: nil))
        ?? NSMutableAttributedString(string: html)

        let font = UIFont.preferredFont(forTextStyle: textStyle)
        base.addAttribute(.font, value: font, range: NSRange(location: 0, length: base.length))

        return base
    }
}

