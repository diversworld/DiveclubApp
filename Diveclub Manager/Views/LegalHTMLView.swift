//
//  LegalHTMLView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 26.02.26.
//

import SwiftUI
import WebKit

struct LegalHTMLView: View {
    let title: String
    let html: String

    var body: some View {
        Group {
            if html.isEmpty {
                ContentUnavailableView("Keine Daten", systemImage: "doc.text", description: Text("Kein Inhalt verfügbar."))
            } else {
                WebViewHTML(html: wrapInHTMLDocument(html))
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func wrapInHTMLDocument(_ fragment: String) -> String {
        """
        <!doctype html>
        <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
              body { font-family: -apple-system, Helvetica, Arial; padding: 16px; }
              h1,h2,h3 { margin-top: 1.2em; }
              a { word-break: break-word; }
            </style>
          </head>
          <body>
            \(fragment)
          </body>
        </html>
        """
    }
}

struct WebViewHTML: UIViewRepresentable {
    let html: String

    func makeUIView(context: Context) -> WKWebView {
        let web = WKWebView(frame: .zero)
        web.isOpaque = false
        web.backgroundColor = .clear
        web.scrollView.backgroundColor = .clear
        return web
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(html, baseURL: nil)
    }
}
