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
        content
            .navigationTitle("TÜV Buchung")
            .navigationBarTitleDisplayMode(.inline)
            .task(id: proposalId) {
                await vm.loadProposal(id: proposalId)
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
    }

    // MARK: - Content Switch

    @ViewBuilder
    private var content: some View {
        if vm.isLoading {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)

        } else if let err = vm.errorMessage {
            ContentUnavailableView("Fehler", systemImage: "exclamationmark.triangle", description: Text(err))

        } else if let proposal = vm.proposal {
            TankCheckDetailList(
                proposal: proposal,
                vm: vm,
                tankSizes: tankSizes,
                tankSizeLabel: tankSizeLabel,
                formatCurrency: formatCurrency
            )

        } else {
            ContentUnavailableView(
                "Keine Daten",
                systemImage: "doc.text.magnifyingglass",
                description: Text("TÜV-Angebot konnte nicht geladen werden.")
            )
        }
    }

    // MARK: - Sizes

    private var tankSizes: [(key: String, label: String)] {
        [
            ("2", "2 L"), ("3", "3 L"), ("4", "4 L"), ("5", "5 L"),
            ("7", "7 L"), ("8", "8 L"), ("10", "10 L"), ("12", "12 L"),
            ("15", "15 L"), ("18", "18 L"), ("20", "20 L"),
            ("11", "40 cft"), ("22", "80 cft")
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

//
// MARK: - Subviews
//

private struct TankCheckDetailList: View {

    let proposal: TankCheckProposalDetailDTO
    @ObservedObject var vm: TankCheckDetailViewModel

    let tankSizes: [(key: String, label: String)]
    let tankSizeLabel: (String) -> String
    let formatCurrency: (Decimal) -> String

    var body: some View {
        List {
            ProposalHeaderSection(proposal: proposal)

            DefaultArticlesSection(
                articles: vm.defaultArticlesForUI(),
                formatCurrency: formatCurrency
            )

            TanksSection(
                vm: vm,
                tankSizes: tankSizes,
                tankSizeLabel: tankSizeLabel,
                formatCurrency: formatCurrency
            )

            BookingNotesSection(bookingNotes: $vm.bookingNotes)

            TotalSection(total: vm.totalPrice, formatCurrency: formatCurrency)

            SubmitSection(
                isSubmitting: vm.isSubmitting,
                bookingError: vm.bookingError,
                submit: { Task { await vm.submitBooking() } }
            )
        }
    }
}

private struct ProposalHeaderSection: View {
    let proposal: TankCheckProposalDetailDTO
    @State private var isNotesExpanded = false   // ✅ NEU

    var body: some View {
        Section {
            Text(proposal.title.isEmpty ? "TÜV Angebot #\(proposal.id)" : proposal.title)
                .font(.headline)

            if let notes = proposal.notes, !notes.isEmpty {
                ExpandableHTMLText(
                    html: notes,
                    textStyle: .body,
                    collapsedLineLimit: 6,
                    isExpanded: $isNotesExpanded          // ✅ NEU
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let vendor = proposal.vendorName, !vendor.isEmpty {
                Label(vendor, systemImage: "building.2")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let ts = proposal.proposalDate {
                let date = Date(timeIntervalSince1970: TimeInterval(ts))
                Label(date.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct DefaultArticlesSection: View {
    let articles: [TankCheckArticleDTO]
    let formatCurrency: (Decimal) -> String

    var body: some View {
        if !articles.isEmpty {
            Section("Enthalten (Pflicht)") {
                ForEach(articles) { a in
                    HStack {
                        Text(a.title) // falls du decodedEntities brauchst: a.title.decodedEntities
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
    }
}

private struct BookingNotesSection: View {
    @Binding var bookingNotes: String

    var body: some View {
        Section("Hinweis") {
            TextField("Hinweis zur Sammelprüfung (optional)", text: $bookingNotes, axis: .vertical)
                .lineLimit(3...6)
        }
    }
}

private struct TotalSection: View {
    let total: Decimal
    let formatCurrency: (Decimal) -> String

    var body: some View {
        Section {
            HStack {
                Text("Gesamtpreis")
                    .font(.headline)
                Spacer()
                Text(formatCurrency(total))
                    .font(.headline)
            }
        }
    }
}

private struct SubmitSection: View {
    let isSubmitting: Bool
    let bookingError: String?
    let submit: () -> Void

    var body: some View {
        Section {
            if isSubmitting {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Sende Buchung …").foregroundStyle(.secondary)
                }
            } else {
                Button(action: submit) {
                    Label("TÜV-Prüfung buchen", systemImage: "checkmark.seal.fill")
                }
                .buttonStyle(.borderedProminent)
            }

            if let err = bookingError {
                Text(err).foregroundStyle(.red)
            }
        }
    }
}

private struct TanksSection: View {
    @ObservedObject var vm: TankCheckDetailViewModel

    let tankSizes: [(key: String, label: String)]
    let tankSizeLabel: (String) -> String
    let formatCurrency: (Decimal) -> String

    var body: some View {
        Section("Flaschen") {
            ForEach(vm.items.indices, id: \.self) { idx in
                TankEditorRow(
                    vm: vm,
                    index: idx,
                    tankSizes: tankSizes,
                    tankSizeLabel: tankSizeLabel,
                    formatCurrency: formatCurrency
                )
            }

            Button {
                vm.items.append(.init())
            } label: {
                Label("Flasche hinzufügen", systemImage: "plus.circle")
            }
        }
    }
}

private struct TankEditorRow: View {
    @ObservedObject var vm: TankCheckDetailViewModel
    let index: Int

    let tankSizes: [(key: String, label: String)]
    let tankSizeLabel: (String) -> String
    let formatCurrency: (Decimal) -> String

    private var itemBinding: Binding<TankCheckDetailViewModel.DraftTankCheckItem> {
        Binding(
            get: { vm.items[index] },
            set: { vm.items[index] = $0 }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack {
                Text("Flasche \(index + 1)").font(.headline)
                Spacer()
                Button(role: .destructive) {
                    vm.items.remove(at: index)
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(vm.items.count <= 1)
            }

            GroupBox("Gespeicherte Flaschen") {
                Toggle("Flaschen im Backend speichern", isOn: $vm.saveTanksToBackend)
                    .onChange(of: vm.saveTanksToBackend) { _, _ in
                        Task { await vm.loadSavedTanks() }
                    }

                if let err = vm.tanksError {
                    Text(err).foregroundStyle(.red)
                }

                if vm.savedTanks.isEmpty {
                    Text("Keine gespeicherten Flaschen vorhanden.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Menu {
                        ForEach(vm.savedTanks) { t in
                            let used = vm.isSavedTankAlreadySelected(t, excluding: index)

                            Button {
                                vm.applySavedTank(t, to: index)
                            } label: {
                                if used {
                                    Text("✅ \(t.serialNumber) • \(tankSizeLabel(t.size)) (bereits gewählt)")
                                } else {
                                    Text("\(t.serialNumber) • \(tankSizeLabel(t.size))")
                                }
                            }
                            .disabled(used)
                        }
                    } label: {
                        Label("Gespeicherte Flasche auswählen", systemImage: "bookmark")
                    }

                    if !vm.items[index].serialNumber.isEmpty {
                        Text("Ausgewählt: \(vm.items[index].serialNumber)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            TextField("Seriennummer", text: itemBinding.serialNumber)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .onChange(of: itemBinding.serialNumber.wrappedValue) { _, _ in
                    vm.tanksError = nil
                }

            TextField("Hersteller (optional)", text: itemBinding.manufacturer)
            TextField("BAZ / Norm (optional)", text: itemBinding.bazNumber)

            Picker("Größe", selection: itemBinding.size) {
                ForEach(tankSizes, id: \.key) { key, label in
                    Text(label).tag(key)
                }
            }

            Toggle("O2-clean", isOn: itemBinding.o2clean)

            optionalArticles

            TextField("Hinweis zur Flasche (optional)", text: itemBinding.notes, axis: .vertical)
                .lineLimit(2...5)

            HStack {
                Text("Preis Flasche \(index + 1)")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formatCurrency(vm.priceForItem(vm.items[index])))
                    .foregroundStyle(.secondary)
            }

            Button {
                vm.saveItemAsTank(vm.items[index])
            } label: {
                Label("Flasche speichern", systemImage: "tray.and.arrow.down")
            }
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var optionalArticles: some View {
        let opt = vm.optionalArticlesForUI()
        if !opt.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Optionale Leistungen")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(opt) { a in
                    Toggle(isOn: Binding(
                        get: { itemBinding.selectedOptionalArticleIds.wrappedValue.contains(a.id) },
                        set: { on in
                            if on {
                                itemBinding.selectedOptionalArticleIds.wrappedValue.insert(a.id)
                            } else {
                                itemBinding.selectedOptionalArticleIds.wrappedValue.remove(a.id)
                            }
                        }
                    )) {
                        HStack {
                            Text(a.title)
                            Spacer()
                            Text(formatCurrency(a.priceBruttoDecimal))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.top, 4)
        }
    }
}
