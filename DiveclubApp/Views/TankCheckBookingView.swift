//
//  TankCheckBookingView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 09.02.26.
//

import SwiftUI

struct TankCheckBookingView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var bookingVM = TankCheckBookingViewModel()
    @StateObject private var tankStore = TankStore.shared
    @StateObject private var auth = AuthManager.shared

    let detail: TankCheckProposalDetailDTO

    @State private var bookingNotes: String = ""
    @State private var selectedArticleIds: Set<Int> = []
    @State private var selectedTankIds: Set<UUID> = []
    @State private var adHocTanks: [ScubaTank] = []

    @State private var showAddSavedTank = false
    @State private var showAddAdhocTank = false

    private var isMember: Bool { auth.isLoggedIn }

    var body: some View {
        NavigationStack {
            List {
                Section("Ausgewählte Artikel") {
                    if detail.articles.isEmpty {
                        Text("Keine Artikel verfügbar.").foregroundStyle(.secondary)
                    } else {
                        ForEach(detail.articles.sorted(by: { ($0.sorting ?? 0) < ($1.sorting ?? 0) })) { a in
                            Button {
                                toggleArticle(a.id)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(a.title)
                                        if let brutto = a.articlePriceBrutto {
                                            Text("\(NSDecimalNumber(decimal: brutto)) €")
                                                .font(.footnote)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: selectedArticleIds.contains(a.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedArticleIds.contains(a.id) ? Color.accentColor : .secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if isMember {
                    Section("Meine Flaschen (gespeichert)") {
                        if tankStore.myTanks.isEmpty {
                            Text("Noch keine Flaschen gespeichert.").foregroundStyle(.secondary)
                        } else {
                            ForEach(tankStore.myTanks) { t in
                                Button {
                                    toggleTank(t.id)
                                } label: {
                                    HStack {
                                        TankSummaryRow(tank: t)
                                        Spacer()
                                        Image(systemName: selectedTankIds.contains(t.id) ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(selectedTankIds.contains(t.id) ? Color.accentColor : .secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Button { showAddSavedTank = true } label: {
                            Label("Flasche speichern", systemImage: "plus")
                        }
                    }

                    Section("Zusätzliche Flasche (einmalig)") {
                        ForEach(adHocTanks) { t in TankSummaryRow(tank: t) }
                            .onDelete { adHocTanks.remove(atOffsets: $0) }

                        Button { showAddAdhocTank = true } label: {
                            Label("Einmalige Flasche hinzufügen", systemImage: "plus.circle")
                        }
                    }
                } else {
                    Section("Flaschen anmelden (Nichtmitglied)") {
                        ForEach(adHocTanks) { t in TankSummaryRow(tank: t) }
                            .onDelete { adHocTanks.remove(atOffsets: $0) }

                        Button { showAddAdhocTank = true } label: {
                            Label("Flasche hinzufügen", systemImage: "plus.circle")
                        }

                        Text("Hinweis: Als Nichtmitglied werden Flaschen nicht dauerhaft gespeichert.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                if detail.addNotes == true {
                    Section("Notizen zur Buchung") {
                        TextField("Optional: Hinweise", text: $bookingNotes, axis: .vertical)
                            .lineLimit(2...6)
                    }
                }

                if let err = bookingVM.error {
                    Section { Text(err).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Anmeldung")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Schließen") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(bookingVM.isSubmitting ? "Sende…" : "Buchen") {
                        Task { await submit() }
                    }
                    .fontWeight(.semibold)
                    .disabled(bookingVM.isSubmitting)
                }
            }
            .onAppear {
                // Default-Artikel vorauswählen
                let defaults = detail.articles.filter { $0.isDefault }.map { $0.id }
                selectedArticleIds.formUnion(defaults)
            }
            .sheet(isPresented: $showAddSavedTank) {
                NavigationStack {
                    TankEditorView(mode: .create) { newTank in
                        tankStore.addTank(newTank)
                    }
                }
            }
            .sheet(isPresented: $showAddAdhocTank) {
                NavigationStack {
                    TankEditorView(mode: .create) { newTank in
                        adHocTanks.append(newTank)
                    }
                }
            }
        }
    }

    private func toggleArticle(_ id: Int) {
        if selectedArticleIds.contains(id) { selectedArticleIds.remove(id) }
        else { selectedArticleIds.insert(id) }
    }

    private func toggleTank(_ id: UUID) {
        if selectedTankIds.contains(id) { selectedTankIds.remove(id) }
        else { selectedTankIds.insert(id) }
    }

    private func submit() async {
        bookingVM.error = nil

        let memberSelected = tankStore.myTanks.filter { selectedTankIds.contains($0.id) }
        let allTanks = memberSelected + adHocTanks
        guard !allTanks.isEmpty else {
            bookingVM.error = "Bitte mindestens eine Flasche auswählen oder hinzufügen."
            return
        }

        let articleIds = Array(selectedArticleIds).sorted()

        // Optional: Wenn pro Flasche eigene Artikel gewählt werden sollen,
        // erweitern wir UI später — aktuell gilt Auswahl für alle Items.
        let items: [TankCheckBookingItemPayload] = allTanks.map { t in
            TankCheckBookingItemPayload(
                serialNumber: t.serialNumber,
                manufacturer: nil,
                bazNumber: nil,
                size: "\(t.volumeLiters)",
                o2clean: nil,
                articles: articleIds,
                notes: nil
            )
        }

        let payload = TankCheckBookingPayload(
            proposalId: detail.id,
            notes: (bookingNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : bookingNotes),
            items: items
        )

        let ok = await bookingVM.submit(payload)
        if ok { dismiss() }
    }
}

// Minimal helper row (falls du sie nicht schon zentral hast)
private struct TankSummaryRow: View {
    let tank: ScubaTank
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(tank.nickname) • \(tank.volumeLiters)L / \(tank.workingPressureBar)bar")
            Text("SN: \(tank.serialNumber)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
