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

    @State private var showSuccess = false

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)

            } else if let err = vm.errorMessage {
                ContentUnavailableView("Fehler", systemImage: "exclamationmark.triangle", description: Text(err))

            } else if let proposal = vm.proposal {
                List {

                    Section {
                        Text(proposal.title)
                            .font(.headline)

                        if let notes = proposal.notes, !notes.isEmpty {
                            HTMLTextView(html: notes, textStyle: .footnote)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    Section("Gespeicherte Flaschen") {
                        Toggle("Flaschen im Backend speichern", isOn: $vm.saveTanksToBackend)
                            .foregroundStyle(.secondary)

                        Button {
                            Task { await vm.loadSavedTanks() }
                        } label: {
                            Label("Gespeicherte Flaschen aktualisieren", systemImage: "arrow.clockwise")
                        }
                    }
                    // Pflichtartikel (nur Anzeige)
                    if !vm.defaultArticlesForUI().isEmpty {
                        Section("Enthalten (Pflicht)") {
                            ForEach(vm.defaultArticlesForUI()) { a in
                                HStack {
                                    Text(a.title.decodedEntities)
                                    Spacer()
                                    Text(formatCurrency(a.priceBruttoDecimal))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Text("Pflichtartikel können nicht abgewählt werden.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Flaschen
                    Section("Flaschen") {
                        ForEach(Array(vm.items.enumerated()), id: \.element.id) { idx, _ in
                            tankEditor(index: idx)
                        }

                        Button {
                            vm.items.append(.init())
                        } label: {
                            Label("Flasche hinzufügen", systemImage: "plus.circle")
                        }
                    }

                    // Booking Notes
                    Section("Hinweis") {
                        TextField("Hinweis zur Sammelprüfung (optional)", text: $vm.bookingNotes, axis: .vertical)
                            .lineLimit(3...6)
                    }

                    // Total
                    Section {
                        HStack {
                            Text("Gesamtpreis")
                                .font(.headline)
                            Spacer()
                            Text(formatCurrency(vm.totalPrice))
                                .font(.headline)
                        }
                    }

                    // Submit
                    Section {
                        if vm.isSubmitting {
                            HStack(spacing: 10) {
                                ProgressView()
                                Text("Sende Buchung …").foregroundStyle(.secondary)
                            }
                        } else {
                            Button {
                                Task { await vm.submitBooking() }
                            } label: {
                                Label("TÜV-Prüfung buchen", systemImage: "checkmark.seal.fill")
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        if let err = vm.bookingError {
                            Text(err).foregroundStyle(.red)
                        }
                    }
                }
                .onChange(of: vm.bookingSuccess) { _, ok in
                    if ok { showSuccess = true }
                }
                .alert("Buchung erfolgreich", isPresented: $showSuccess) {
                    Button("OK") {
                        vm.bookingSuccess = false
                        showSuccess = false
                    }
                } message: {
                    Text("Deine Flaschen wurden für die Sammelprüfung angemeldet.")
                }

            } else {
                ContentUnavailableView(
                    "Keine Daten",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("TÜV-Angebot konnte nicht geladen werden.")
                )
            }
        }
        .navigationTitle("TÜV Buchung")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: proposalId) {
            await vm.loadProposal(id: proposalId)
        }
        .onChange(of: vm.items) { _, _ in
            // Trigger UI and payload refresh when items change
            // (Totals and per-item prices are computed from vm.items)
        }
    }

    // MARK: - Tank Editor

    @ViewBuilder
    private func tankEditor(index: Int) -> some View {
        let binding = Binding(
            get: { vm.items[index] },
            set: { newValue in
                // Ensure changes to size and pricing-relevant fields are propagated
                vm.items[index] = newValue
                // Re-assign to trigger didSet/publish and keep backend payload in sync
                vm.items[index] = vm.items[index]
            }
        )

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Flasche \(index + 1)")
                    .font(.headline)
                Spacer()
                Button(role: .destructive) {
                    vm.items.remove(at: index)
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(vm.items.count <= 1)
            }

            Section("Gespeicherte Flaschen") {
                Toggle("Flaschen im Backend speichern", isOn: $vm.saveTanksToBackend)
                    .onChange(of: vm.saveTanksToBackend) { _, _ in
                        Task { await vm.loadSavedTanks() }
                    }

                if let err = vm.tanksError {
                    Text(err).foregroundStyle(.red)
                }

                // Saved Tanks picker (wenn vorhanden)
                if !vm.savedTanks.isEmpty {
                    Section {
                        Menu {
                            ForEach(vm.savedTanks) { t in
                                Button {
                                    vm.applySavedTank(t, to: index)
                                } label: {
                                    Text("\(t.serialNumber) • \(tankSizeLabel(t.size))")
                                }
                            }
                        } label: {
                            Label("Gespeicherte Flasche auswählen", systemImage: "bookmark")
                        }

                        // optional: kleine Bestätigung anzeigen
                        if !vm.items[index].serialNumber.isEmpty {
                            Text("Ausgewählt: \(vm.items[index].serialNumber)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    ForEach(vm.savedTanks) { t in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(t.displayLine).font(.subheadline)
                                if !t.manufacturer.isEmpty || !t.bazNumber.isEmpty {
                                    Text([t.manufacturer, t.bazNumber].filter { !$0.isEmpty }.joined(separator: " • "))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if t.o2clean {
                                Text("O₂-clean")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.secondary.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                vm.deleteSavedTank(t)
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                    }
                }
            }

            TextField("Seriennummer", text: binding.serialNumber)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)

            TextField("Hersteller (optional)", text: binding.manufacturer)
            TextField("BAZ / Norm (optional)", text: binding.bazNumber)

            Picker("Größe", selection: binding.size) {
                ForEach(tankSizes, id: \.key) { key, label in
                    Text(label).tag(key)
                }
            }

            Toggle("O2-clean", isOn: binding.o2clean)

            // optionale Artikel (Default sind separat / Pflicht)
            if !vm.optionalArticlesForUI().isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Optionale Leistungen")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ForEach(vm.optionalArticlesForUI()) { a in
                        Toggle(isOn: Binding(
                            get: { binding.selectedOptionalArticleIds.wrappedValue.contains(a.id) },
                            set: { on in
                                if on {
                                    binding.selectedOptionalArticleIds.wrappedValue.insert(a.id)
                                } else {
                                    binding.selectedOptionalArticleIds.wrappedValue.remove(a.id)
                                }
                            }
                        )) {
                            HStack {
                                Text(a.title.decodedEntities)
                                Spacer()
                                Text(formatCurrency(a.priceBruttoDecimal))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(.top, 4)
            }

            TextField("Hinweis zur Flasche (optional)", text: binding.notes, axis: .vertical)
                .lineLimit(2...5)

            // Preis pro Flasche
            HStack {
                Text("Preis Flasche \(index + 1)")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formatCurrency(vm.priceForItem(vm.items[index])))
                    .foregroundStyle(.secondary)
            }

            // Save tank
            Button {
                vm.saveItemAsTank(vm.items[index])
            } label: {
                Label("Flasche speichern", systemImage: "tray.and.arrow.down")
            }
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 6)
        .onChange(of: vm.items[index]) { _, updated in
            // Keep derived values (like price) and size synced for backend submission
            vm.items[index] = updated
        }
    }

    // MARK: - Sizes

    private var tankSizes: [(key: String, label: String)] {
        [
            ("2", "2 L"),
            ("3", "3 L"),
            ("4", "4 L"),
            ("5", "5 L"),
            ("7", "7 L"),
            ("8", "8 L"),
            ("10", "10 L"),
            ("12", "12 L"),
            ("15", "15 L"),
            ("18", "18 L"),
            ("20", "20 L"),
            ("11", "40 cft"),
            ("22", "80 cft")
        ]
    }

    private func tankSizeLabel(_ key: String) -> String {
        tankSizes.first(where: { $0.key == key })?.label ?? key
    }

    // MARK: - Currency

    private func formatCurrency(_ value: Decimal) -> String {
        let ns = value as NSDecimalNumber
        let f = NumberFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.numberStyle = .currency
        return f.string(from: ns) ?? "\(ns)"
    }
}
