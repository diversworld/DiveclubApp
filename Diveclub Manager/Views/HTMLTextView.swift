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
    let textStyle: UIFont.TextStyle

    /// nil = unbegrenzt (expanded), sonst z.B. 6 (collapsed)
    var maxLines: Int? = nil

    /// Optional: einheitliche Textfarbe (empfohlen)
    var textColor: UIColor = .secondaryLabel

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.isEditable = false
        tv.isSelectable = true
        tv.isScrollEnabled = false
        tv.backgroundColor = .clear

        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0

        tv.adjustsFontForContentSizeCategory = true

        // wichtig für SwiftUI height
        tv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        tv.setContentCompressionResistancePriority(.required, for: .vertical)

        // damit Truncation funktioniert
        tv.textContainer.lineBreakMode = .byTruncatingTail

        return tv
    }

    func updateUIView(_ tv: UITextView, context: Context) {
        // ✅ collapse/expand anwenden
        tv.textContainer.maximumNumberOfLines = maxLines ?? 0

        // nur neu rendern, wenn nötig
        if context.coordinator.lastHTML == html,
           context.coordinator.lastStyle == textStyle,
           context.coordinator.lastMaxLines == maxLines {
            return
        }
        context.coordinator.lastHTML = html
        context.coordinator.lastStyle = textStyle
        context.coordinator.lastMaxLines = maxLines

        let cacheKey = "\(textStyle.rawValue)|\(maxLines ?? 0)|\(html.hashValue)"
        let attributed: NSMutableAttributedString

        if let cached = HTMLAttributedStringCache.shared.get(cacheKey) as? NSMutableAttributedString {
            attributed = cached
        } else {
            let baseFont = UIFont.preferredFont(forTextStyle: textStyle)

            let data = Data(html.utf8)
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]

            attributed = (try? NSMutableAttributedString(data: data, options: options, documentAttributes: nil))
            ?? NSMutableAttributedString(string: stripHTMLFallback(html))

            let full = NSRange(location: 0, length: attributed.length)
            attributed.addAttributes([.font: baseFont, .foregroundColor: textColor], range: full)

            HTMLAttributedStringCache.shared.set(attributed, for: cacheKey)
        }

        tv.attributedText = attributed
        tv.invalidateIntrinsicContentSize()
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView tv: UITextView, context: Context) -> CGSize? {
        let targetWidth: CGFloat
        if let width = proposal.width {
            targetWidth = width
        } else if let window = tv.window, let scene = window.windowScene {
            targetWidth = scene.screen.bounds.width
        } else {
            targetWidth = max(tv.bounds.width, 1)
        }

        tv.textContainer.size = CGSize(width: targetWidth, height: .greatestFiniteMagnitude)
        let size = tv.sizeThatFits(CGSize(width: targetWidth, height: .greatestFiniteMagnitude))
        return CGSize(width: targetWidth, height: ceil(size.height))
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var lastHTML: String?
        var lastStyle: UIFont.TextStyle?
        var lastMaxLines: Int?
    }

    private func stripHTMLFallback(_ html: String) -> String {
        html
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
    }
}
