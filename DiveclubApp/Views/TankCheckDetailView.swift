//
//  TankCheckDetailView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 09.02.26.
//

import SwiftUI

struct TankCheckDetailView: View {
    let proposalId: Int
    @StateObject private var vm = TankCheckDetailViewModel()
    @State private var showBooking = false

    var body: some View {
        List {
            if vm.isLoading {
                ProgressView("Lade Angebot …")
            }
            if let err = vm.error {
                Text(err).foregroundStyle(.red)
            }

            if let d = vm.detail {
                Section("Termin") {
                    LabeledContent("Titel") { Text(d.title) }
                    if let date = d.proposalDate {
                        LabeledContent("Prüfdatum") { Text(date, style: .date) }
                    }
                    if let vendor = d.vendorName, !vendor.isEmpty {
                        LabeledContent("Prüfer") { Text(vendor) }
                    }
                }

                if let html = d.notesHTML, !html.isEmpty {
                    Section("Hinweise") {
                        // Minimal: HTML als Text anzeigen (Entities sind eh schon escaped)
                        Text(htmlStripped(html))
                            .foregroundStyle(.primary)
                    }
                }

                Section("Artikel") {
                    if d.articles.isEmpty {
                        Text("Keine Artikel verfügbar.").foregroundStyle(.secondary)
                    } else {
                        ForEach(d.articles.sorted(by: { ($0.sorting ?? 0) < ($1.sorting ?? 0) })) { a in
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(a.title)
                                    if let size = a.articleSize, !size.isEmpty {
                                        Text("Größe: \(size)").font(.footnote).foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                if let brutto = a.articlePriceBrutto {
                                    Text("\(NSDecimalNumber(decimal: brutto)) €")
                                        .foregroundStyle(.secondary)
                                }
                                if a.isDefault {
                                    Image(systemName: "star.fill").font(.footnote)
                                }
                            }
                        }
                    }
                }

                Section {
                    Button {
                        showBooking = true
                    } label: {
                        Label("Details & Anmeldung", systemImage: "checkmark.circle.fill")
                    }
                }
            }
        }
        .navigationTitle("TÜV-Angebot")
        .task { await vm.load(id: proposalId) }
        .sheet(isPresented: $showBooking) {
            if let d = vm.detail {
                TankCheckBookingView(detail: d)
            } else {
                ProgressView("Lade …")
            }
        }
    }

    private func htmlStripped(_ html: String) -> String {
        // sehr einfacher Strip (für schöne Darstellung später WebView/AttributedString)
        html
            .replacingOccurrences(of: "<br>", with: "\n")
            .replacingOccurrences(of: "<br/>", with: "\n")
            .replacingOccurrences(of: "<br />", with: "\n")
            .replacingOccurrences(of: "</p>", with: "\n\n")
            .replacingOccurrences(of: "<p>", with: "")
            .replacingOccurrences(of: "</p>", with: "")
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
