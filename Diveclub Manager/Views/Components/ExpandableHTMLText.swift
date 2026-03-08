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
    var textStyle: UIFont.TextStyle = .body
    var collapsedLineLimit: Int = 6

    @Binding var isExpanded: Bool

    var scrollProxy: ScrollViewProxy? = nil
    var scrollID: AnyHashable? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            HTMLTextView(
                html: html,
                textStyle: textStyle,
                maxLines: isExpanded ? nil : collapsedLineLimit
            )
            .fixedSize(horizontal: false, vertical: true)
            .foregroundStyle(.secondary)

            HStack {
                Spacer()
                Button {
                    let willExpand = !isExpanded

                    withAnimation(.easeInOut(duration: 0.25)) {
                        isExpanded.toggle()
                    }

                    if willExpand,
                       let proxy = scrollProxy,
                       let id = scrollID {

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                proxy.scrollTo(id, anchor: .top)
                            }
                        }
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
}
