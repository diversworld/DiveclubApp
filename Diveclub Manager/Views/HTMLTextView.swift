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

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.isEditable = false
        tv.isSelectable = true
        tv.isScrollEnabled = false               // wichtig
        tv.backgroundColor = .clear
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        tv.adjustsFontForContentSizeCategory = true

        // sorgt dafür, dass SwiftUI vertikal wachsen darf
        tv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        tv.setContentCompressionResistancePriority(.required, for: .vertical)

        return tv
    }

    func updateUIView(_ tv: UITextView, context: Context) {
        // nur neu setzen, wenn Inhalt sich geändert hat (kleiner Performance-Boost)
        if context.coordinator.lastHTML == html,
           context.coordinator.lastStyle == textStyle {
            return
        }
        context.coordinator.lastHTML = html
        context.coordinator.lastStyle = textStyle

        let baseFont = UIFont.preferredFont(forTextStyle: textStyle)

        let data = Data(html.utf8)
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        let attributed = (try? NSMutableAttributedString(data: data, options: options, documentAttributes: nil))
            ?? NSMutableAttributedString(string: stripHTMLFallback(html))

        attributed.addAttributes([.font: baseFont], range: NSRange(location: 0, length: attributed.length))
        tv.attributedText = attributed

        // Layout invalidieren – wichtig für Neuberechnung
        tv.invalidateIntrinsicContentSize()
    }

    /// ✅ Der entscheidende Teil: SwiftUI fragt die gewünschte Größe ab.
    func sizeThatFits(_ proposal: ProposedViewSize,
                      uiView tv: UITextView,
                      context: Context) -> CGSize? {

        // 1️⃣ Bevorzugt: SwiftUI gibt uns eine Breite
        let targetWidth: CGFloat

        if let width = proposal.width {
            targetWidth = width
        }
        // 2️⃣ Fallback: tatsächliche Layout-Breite aus dem Window/Scene
        else if let window = tv.window,
                let scene = window.windowScene {
            targetWidth = scene.screen.bounds.width
        }
        // 3️⃣ Letzter Fallback (sehr selten)
        else {
            targetWidth = tv.bounds.width
        }

        tv.textContainer.size = CGSize(
            width: targetWidth,
            height: .greatestFiniteMagnitude
        )

        let size = tv.sizeThatFits(
            CGSize(width: targetWidth,
                   height: .greatestFiniteMagnitude)
        )

        return CGSize(
            width: targetWidth,
            height: ceil(size.height)
        )
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var lastHTML: String?
        var lastStyle: UIFont.TextStyle?
    }

    private func stripHTMLFallback(_ html: String) -> String {
        html
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
    }
}
