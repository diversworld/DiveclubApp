//
//  ExpandableHTMLText.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 10.02.26.
//

import SwiftUI
import UIKit

/// Zeigt HTML-Text erst kurz (lineLimit) und klappt bei Bedarf auf.
/// Stabil in List/Section (kein Scrollen, kein Height-Measuring).
struct ExpandableHTMLText: View {
    let html: String
    var textStyle: UIFont.TextStyle = .footnote
    var collapsedLineLimit: Int = 6

    @State private var isExpanded = false
    @State private var shouldShowButton = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            HTMLTextView(
                html: html,
                textStyle: textStyle,
            )
            .fixedSize(horizontal: false, vertical: true)
            .foregroundStyle(.secondary)

            if shouldShowButton {
                HStack {
                    Spacer()

                    Button {
                        withAnimation(.snappy) {
                            isExpanded.toggle()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(isExpanded ? "Weniger anzeigen" : "Mehr anzeigen")
                                .font(.caption)
                                .fontWeight(.semibold)

                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(.tint)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .task(id: detectKey) {
            // Heuristik: Button nur bei "langen" Texten
            let plain = html.htmlToPlainText
            shouldShowButton = plain.count > 350
        }
    }

    private var detectKey: Int { html.hashValue }
}
