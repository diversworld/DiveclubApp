//
//  ExpandableHTMLText.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 10.02.26.
//

import SwiftUI
import UIKit

private struct FullHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct CollapsedHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct ExpandableHTMLText: View {
    let html: String
    var textStyle: UIFont.TextStyle = .body
    var collapsedLineLimit: Int = 6

    @Binding var isExpanded: Bool

    var scrollProxy: ScrollViewProxy? = nil
    var scrollID: AnyHashable? = nil

    @State private var fullHeight: CGFloat = 0
    @State private var collapsedHeight: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            // ✅ Sichtbarer Text (nur dieser bestimmt die Höhe!)
            HTMLTextView(
                html: html,
                textStyle: textStyle,
                maxLines: isExpanded ? nil : collapsedLineLimit
            )
            .fixedSize(horizontal: false, vertical: true)
            .foregroundStyle(.secondary)

            // ✅ Mess-Overlay (beeinflusst Layout NICHT)
            .overlay(alignment: .topLeading) {
                // Full height
                HTMLTextView(html: html, textStyle: textStyle, maxLines: nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(key: FullHeightKey.self, value: geo.size.height)
                        }
                    )
                    .opacity(0.001)
                    .allowsHitTesting(false)

                // Collapsed height (IMMER mit collapsedLineLimit messen!)
                HTMLTextView(html: html, textStyle: textStyle, maxLines: collapsedLineLimit)
                    .fixedSize(horizontal: false, vertical: true)
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(key: CollapsedHeightKey.self, value: geo.size.height)
                        }
                    )
                    .opacity(0.001)
                    .allowsHitTesting(false)
            }

            if showButton {
                HStack {
                    Spacer()
                    Button {
                        let willExpand = !isExpanded
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isExpanded.toggle()
                        }

                        // Pro-Move scroll nur beim Expand
                        if willExpand, let proxy = scrollProxy, let id = scrollID {
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
        .onPreferenceChange(FullHeightKey.self) { h in
            guard h > 0, abs(h - fullHeight) > 0.5 else { return }
            DispatchQueue.main.async { fullHeight = h }
        }
        .onPreferenceChange(CollapsedHeightKey.self) { h in
            guard h > 0, abs(h - collapsedHeight) > 0.5 else { return }
            DispatchQueue.main.async { collapsedHeight = h }
        }
    }

    private var showButton: Bool {
        // Expanded: immer Button zeigen (damit “Weniger anzeigen” möglich bleibt)
        if isExpanded { return true }
        // Collapsed: nur wenn wirklich abgeschnitten
        return fullHeight > collapsedHeight + 1
    }
}

