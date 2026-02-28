//
//  ExpandableHTMLText.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 10.02.26.
//

import SwiftUI
import UIKit

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
                maxLines: isExpanded ? nil : collapsedLineLimit,
                textColor: .secondaryLabel
            )
            .fixedSize(horizontal: false, vertical: true)

            if shouldShowButton {
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
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
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .task(id: html.hashValue) {
            // einfache Heuristik (ok)
            shouldShowButton = html.htmlToPlainText.count > 350
        }
    }
}

