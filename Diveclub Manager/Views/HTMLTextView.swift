//
//  HTMLTextView.swift
//  DiveclubApp
//
//  SwiftUI-native HTML rendering (no UITextView)
//  Swift 6 / iOS 18+ safe
//

import SwiftUI
import UIKit

// MARK: - Cache (NSAttributedString kept inside cache, used on MainActor only)

final class HTMLAttributedStringCache {
    static let shared = HTMLAttributedStringCache()
    private let cache = NSCache<NSString, NSAttributedString>()

    private init() {
        cache.countLimit = 400
    }

    func get(_ key: String) -> NSAttributedString? {
        cache.object(forKey: key as NSString)
    }

    func set(_ value: NSAttributedString, for key: String) {
        cache.setObject(value, forKey: key as NSString)
    }
}

// MARK: - HTMLTextView (SwiftUI only)

struct HTMLTextView: View {
    let html: String
    let textStyle: UIFont.TextStyle

    /// nil = unlimited
    var maxLines: Int? = nil

    /// Optional: own link handler
    var onOpenURL: ((URL) -> Void)? = nil

    @Environment(\.openURL) private var systemOpenURL
    @Environment(\.sizeCategory) private var sizeCategory
    @Environment(\.colorScheme) private var colorScheme

    @State private var rendered: AttributedString?

    var body: some View {
        Group {
            if let rendered {
                Text(rendered)
                    .lineLimit(maxLines)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                // placeholder to avoid layout jumping
                Text("")
                    .lineLimit(maxLines)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        // If you set a custom handler, we override openURL.
        // Otherwise we let the system do its default behavior.
        .environment(\.openURL, OpenURLAction { url in
            if let onOpenURL {
                onOpenURL(url)
                return .handled
            } else {
                // let system handle it (Safari, Mail, etc.)
                return .systemAction(url)
            }
        })
        .task(id: cacheKey) {
            // Build attributed on MainActor to avoid Swift 6 Sendable issues.
            // (HTML parsing is usually fast enough; caching makes it cheap.)
            let ns = buildNSAttributedString()
            let swiftUI = (try? AttributedString(ns, including: \.uiKit)) ?? AttributedString(ns.string)
            rendered = swiftUI
        }
    }

    // MARK: - Cache Key

    private var cacheKey: String {
        "\(textStyle.rawValue)|\(sizeCategory)|\(colorScheme == .dark ? 1 : 0)|\(html.hashValue)"
    }

    // MARK: - Build NSAttributedString (cached)

    @MainActor
    private func buildNSAttributedString() -> NSAttributedString {
        if let cached = HTMLAttributedStringCache.shared.get(cacheKey) {
            return cached
        }

        let ns = makeNSAttributedHTML(html: html, textStyle: textStyle)
        HTMLAttributedStringCache.shared.set(ns, for: cacheKey)
        return ns
    }

    // MARK: - HTML -> NSAttributedString (keep formatting)

    private func makeNSAttributedHTML(html: String, textStyle: UIFont.TextStyle) -> NSAttributedString {
        let data = Data(html.utf8)
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        let base = (try? NSMutableAttributedString(data: data, options: options, documentAttributes: nil))
        ?? NSMutableAttributedString(string: stripHTMLFallback(html))

        let fullRange = NSRange(location: 0, length: base.length)

        // Dynamic Type target size
        let preferred = UIFont.preferredFont(forTextStyle: textStyle)
        let metrics = UIFontMetrics(forTextStyle: textStyle)
        let targetSize = metrics.scaledValue(for: preferred.pointSize)

        // Normalize font size but keep traits (bold/italic)
        base.enumerateAttribute(.font, in: fullRange) { value, range, _ in
            let original = (value as? UIFont) ?? preferred
            let desc = original.fontDescriptor.withSize(targetSize)
            base.addAttribute(.font, value: UIFont(descriptor: desc, size: targetSize), range: range)
        }

        // Ensure readable color when HTML didn't define one
        base.enumerateAttribute(.foregroundColor, in: fullRange) { value, range, _ in
            if value == nil {
                base.addAttribute(.foregroundColor, value: UIColor.label, range: range)
            }
        }

        // Fix paragraph clipping if any
        base.enumerateAttribute(.paragraphStyle, in: fullRange) { value, range, _ in
            let p = (value as? NSMutableParagraphStyle) ?? NSMutableParagraphStyle()
            if p.lineBreakMode == .byClipping { p.lineBreakMode = .byWordWrapping }
            base.addAttribute(.paragraphStyle, value: p, range: range)
        }

        return base
    }

    private func stripHTMLFallback(_ html: String) -> String {
        html
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
    }
}
