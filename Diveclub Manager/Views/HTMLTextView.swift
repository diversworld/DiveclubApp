//
//  HTMLTextView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 09.02.26.
//

//
//  HTMLTextView.swift
//  DiveclubApp
//
//  iOS 18+ final consolidated
//

import SwiftUI
import UIKit

// MARK: - Cache

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

// MARK: - HTMLTextView

struct HTMLTextView: UIViewRepresentable {
    let html: String
    let textStyle: UIFont.TextStyle

    /// nil = unlimited, otherwise collapsed line count
    var maxLines: Int? = nil

    /// Optional: link handler; if nil -> openURL
    var onOpenURL: ((URL) -> Void)? = nil

    /// Optional: callback when current layout is truncated (only meaningful when collapsed)
    var onTruncationChange: ((Bool) -> Void)? = nil

    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.sizeCategory) private var sizeCategory

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.isEditable = false
        tv.isSelectable = true
        tv.isScrollEnabled = false
        tv.backgroundColor = .clear

        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        tv.textContainer.lineBreakMode = .byTruncatingTail
        tv.textContainer.maximumNumberOfLines = maxLines ?? 0

        tv.adjustsFontForContentSizeCategory = true

        tv.dataDetectorTypes = [.link]
        tv.delegate = context.coordinator
        tv.linkTextAttributes = [
            NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue
        ]

        // Let SwiftUI grow vertically
        tv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        tv.setContentCompressionResistancePriority(.required, for: .vertical)

        return tv
    }

    func updateUIView(_ tv: UITextView, context: Context) {
        context.coordinator.onOpenURL = onOpenURL ?? { url in openURL(url) }
        context.coordinator.onTruncationChange = onTruncationChange

        // ✅ Apply line limit first
        let newMaxLines = maxLines ?? 0
        if context.coordinator.lastAppliedMaxLines != newMaxLines {
            context.coordinator.lastAppliedMaxLines = newMaxLines
            tv.textContainer.maximumNumberOfLines = newMaxLines

            // ✅ CRITICAL for “expand actually expands” inside List
            tv.invalidateIntrinsicContentSize()
            tv.setNeedsLayout()
        } else {
            tv.textContainer.maximumNumberOfLines = newMaxLines
        }

        // Cache key: re-render when content / style / dynamic type / appearance changes
        let key = CacheKey(
            html: html,
            textStyle: textStyle,
            sizeCategory: sizeCategory,
            isDark: (colorScheme == .dark)
        ).stringValue

        if context.coordinator.lastKey != key {
            context.coordinator.lastKey = key

            let attributed = HTMLAttributedStringCache.shared.get(key)
                ?? makeAttributedHTML(html: html, textStyle: textStyle, traitCollection: tv.traitCollection)

            if HTMLAttributedStringCache.shared.get(key) == nil {
                HTMLAttributedStringCache.shared.set(attributed, for: key)
            }

            tv.attributedText = attributed

            tv.invalidateIntrinsicContentSize()
            tv.setNeedsLayout()
        }

        // ✅ Truncation check after layout (delayed, retry)
        context.coordinator.scheduleTruncationCheck(tv, collapsedMaxLines: maxLines)
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

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onOpenURL: onOpenURL ?? { url in openURL(url) },
            onTruncationChange: onTruncationChange
        )
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, UITextViewDelegate {
        var onOpenURL: (URL) -> Void
        var onTruncationChange: ((Bool) -> Void)?

        var lastKey: String?
        var lastAppliedMaxLines: Int?

        private var lastReportedTruncated: Bool?
        private var pendingCheckID: UUID?

        init(onOpenURL: @escaping (URL) -> Void, onTruncationChange: ((Bool) -> Void)?) {
            self.onOpenURL = onOpenURL
            self.onTruncationChange = onTruncationChange
        }

        // ✅ iOS 17+ modern link interception (no deprecated UITextItemInteraction)
        @available(iOS 17.0, *)
        func textView(_ textView: UITextView,
                      primaryActionFor textItem: UITextItem,
                      defaultAction: UIAction) -> UIAction? {
            if case .link(let url) = textItem.content {
                onOpenURL(url)
                return nil
            }
            return nil
        }

        func scheduleTruncationCheck(_ tv: UITextView, collapsedMaxLines: Int?) {
            guard let onTruncationChange else { return }

            // Expanded => not truncated (but report it safely, delayed)
            guard collapsedMaxLines != nil else {
                if lastReportedTruncated != false {
                    lastReportedTruncated = false
                    // ✅ delay to avoid “state update during view update”
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                        onTruncationChange(false)
                    }
                }
                return
            }

            let checkID = UUID()
            pendingCheckID = checkID

            func attempt(_ triesLeft: Int) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                    guard self.pendingCheckID == checkID else { return }

                    tv.setNeedsLayout()
                    tv.layoutIfNeeded()

                    // In List, width may appear later
                    if tv.bounds.width <= 10, triesLeft > 0 {
                        attempt(triesLeft - 1)
                        return
                    }

                    let truncated = Self.isTextTruncated(in: tv)
                    if self.lastReportedTruncated != truncated {
                        self.lastReportedTruncated = truncated
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.0) {
                            onTruncationChange(truncated)
                        }
                    }
                }
            }

            attempt(6) // ~0.18s total worst-case
        }

        private static func isTextTruncated(in tv: UITextView) -> Bool {
            let width = tv.bounds.width
            guard width > 10 else { return false }

            tv.textContainer.size = CGSize(width: width, height: .greatestFiniteMagnitude)
            tv.layoutManager.ensureLayout(for: tv.textContainer)

            let glyphRange = tv.layoutManager.glyphRange(for: tv.textContainer)
            var truncated = false

            tv.layoutManager.enumerateLineFragments(forGlyphRange: glyphRange) { _, _, _, lineGlyphRange, stop in
                let tr = tv.layoutManager.truncatedGlyphRange(inLineFragmentForGlyphAt: lineGlyphRange.location)
                if tr.location != NSNotFound && tr.length > 0 {
                    truncated = true
                    stop.pointee = true
                }
            }

            return truncated
        }
    }

    // MARK: - HTML Rendering (keep formatting, correct size)

    private func makeAttributedHTML(
        html: String,
        textStyle: UIFont.TextStyle,
        traitCollection: UITraitCollection
    ) -> NSAttributedString {

        let data = Data(html.utf8)
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        let base = (try? NSMutableAttributedString(data: data, options: options, documentAttributes: nil))
            ?? NSMutableAttributedString(string: stripHTMLFallback(html))

        let fullRange = NSRange(location: 0, length: base.length)

        // Use the preferred point size for the style (prevents “tiny HTML”),
        // but keep each run’s traits (bold/italic/headings).
        let preferred = UIFont.preferredFont(forTextStyle: textStyle)
        let metrics = UIFontMetrics(forTextStyle: textStyle)
        let targetPointSize = metrics.scaledValue(for: preferred.pointSize, compatibleWith: traitCollection)

        base.enumerateAttribute(NSAttributedString.Key.font, in: fullRange) { value, range, _ in
            let original = (value as? UIFont) ?? preferred
            let desc = original.fontDescriptor.withSize(targetPointSize)
            let newFont = UIFont(descriptor: desc, size: targetPointSize)
            base.addAttribute(NSAttributedString.Key.font, value: newFont, range: range)
        }

        // Color only if HTML doesn’t specify
        base.enumerateAttribute(NSAttributedString.Key.foregroundColor, in: fullRange) { value, range, _ in
            if value == nil {
                base.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.label, range: range)
            }
        }

        // Gentle paragraph normalization
        base.enumerateAttribute(NSAttributedString.Key.paragraphStyle, in: fullRange) { value, range, _ in
            let p = (value as? NSMutableParagraphStyle) ?? NSMutableParagraphStyle()
            if p.lineBreakMode == .byClipping { p.lineBreakMode = .byWordWrapping }
            base.addAttribute(NSAttributedString.Key.paragraphStyle, value: p, range: range)
        }

        return base
    }

    private func stripHTMLFallback(_ html: String) -> String {
        html
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
    }
}

// MARK: - CacheKey

private struct CacheKey {
    let html: String
    let textStyle: UIFont.TextStyle
    let sizeCategory: ContentSizeCategory
    let isDark: Bool

    var stringValue: String {
        "\(textStyle.rawValue)|\(sizeCategory)|\(isDark ? 1 : 0)|\(html.hashValue)"
    }
}

