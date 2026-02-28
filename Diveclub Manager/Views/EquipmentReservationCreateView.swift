//
//  EquipmentReservationCreateView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 10.02.26.
//

import SwiftUI

struct EquipmentReservationCreateView: View {
    @StateObject private var vm = EquipmentRentalViewModel()

    var body: some View {
        List {
            ZeitraumSection(startDate: $vm.startDate, endDate: $vm.endDate)
            ReservedForSection(reservedFor: $vm.reservedFor)
            DefaultsSection(defaultNotes: $vm.defaultNotes)

            AssetSelectionSection(vm: vm)

            if let err = vm.errorMessage {
                Section { Text(err).foregroundStyle(.red) }
            }
        }
        .navigationTitle("Neue Reservierung")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Reservieren") {
                    Task { await vm.createReservation() }
                }
                .disabled(vm.selected.isEmpty || vm.isLoading)
            }
        }
        .task { await vm.loadAssets() }
        .refreshable { await vm.loadAssets() }
        .alert(
            "Erfolg",
            isPresented: Binding(
                get: { vm.successMessage != nil },
                set: { _ in vm.successMessage = nil }
            )
        ) {
            Button("OK") {}
        } message: {
            Text(vm.successMessage ?? "")
        }
    }
}

// MARK: - Sections

private struct ZeitraumSection: View {
    @Binding var startDate: Date
    @Binding var endDate: Date

    var body: some View {
        Section("Zeitraum") {
            DatePicker("Start", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
            DatePicker("Ende", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
        }
    }
}

private struct ReservedForSection: View {
    @Binding var reservedFor: String

    var body: some View {
        Section("Optional: Für Mitglied-ID reservieren") {
            TextField("Mitglieds-ID (optional)", text: $reservedFor)
                .keyboardType(.numberPad)
        }
    }
}

private struct DefaultsSection: View {
    @Binding var defaultNotes: String

    var body: some View {
        Section("Zusatzfelder für Items") {
            TextField("Notes (optional)", text: $defaultNotes)
        }
    }
}

private struct AssetSelectionSection: View {
    @ObservedObject var vm: EquipmentRentalViewModel

    var body: some View {
        Section("Auswahl") {
            if vm.isLoading {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Lade Katalog…").foregroundStyle(.secondary)
                }
            } else if vm.visibleAssets.isEmpty {
                Text("Keine Artikel gefunden.").foregroundStyle(.secondary)
            } else {
                ForEach(vm.visibleAssets, id: \.uniqueKey) { asset in
                    AssetRow(
                        asset: asset,
                        isSelected: vm.isSelected(asset),
                        isAvailable: vm.isAvailable(asset),
                        onToggle: { vm.toggleSelection(asset) },
                        editor: { PerItemMetaEditor(asset: asset, vm: vm) }
                    )
                }
            }
        }
    }
}

// MARK: - Row

private struct AssetRow<Editor: View>: View {
    let asset: EquipmentAsset
    let isSelected: Bool
    let isAvailable: Bool
    let onToggle: () -> Void
    @ViewBuilder let editor: () -> Editor

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onToggle) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")

                    VStack(alignment: .leading, spacing: 4) {
                        Text(asset.title)

                        if let details = asset.details, !details.isEmpty {
                            Text(details)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .lineLimit(4)
                        }

                        if let fee = asset.fee, !fee.isEmpty {
                            Text("Gebühr: \(fee)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    if !isAvailable {
                        Text("nicht verfügbar")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)

            NavigationLink { editor() } label: { Text("Bearbeiten") }
                .disabled(!isSelected)
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Editor (✅ types + subType)

private struct PerItemMetaEditor: View {
    let asset: EquipmentAsset
    @ObservedObject var vm: EquipmentRentalViewModel

    @State private var notesText: String = ""
    @State private var typeKey: String? = nil
    @State private var subTypeKey: String? = nil

    private var typeOptions: [(key: String, name: String)] {
        guard let opts = vm.equipmentOptions?.types else { return [] }
        return opts
            .map { (key: $0.key, name: $0.value.name) }
            .sorted { $0.key < $1.key }
    }

    private var subTypeOptions: [(key: String, name: String)] {
        guard
            let t = typeKey,
            let entry = vm.equipmentOptions?.types[t]
        else { return [] }

        return entry.subtypes
            .map { (key: $0.key, name: $0.value) }
            .sorted { $0.key < $1.key }
    }

    var body: some View {
        List {
            Section(asset.title) {
                TextField("Notes", text: $notesText)

                Picker("Typ", selection: Binding(
                    get: { typeKey ?? "" },
                    set: { newVal in
                        let v = newVal.isEmpty ? nil : newVal
                        typeKey = v
                        // Wenn Typ wechselt, Subtype resetten, falls nicht mehr gültig
                        if v == nil { subTypeKey = nil }
                        else if !subTypeOptions.contains(where: { $0.key == subTypeKey }) {
                            subTypeKey = nil
                        }
                    }
                )) {
                    Text("—").tag("")
                    ForEach(typeOptions, id: \.key) { opt in
                        Text(opt.name).tag(opt.key)
                    }
                }

                Picker("Subtyp", selection: Binding(
                    get: { subTypeKey ?? "" },
                    set: { newVal in
                        subTypeKey = newVal.isEmpty ? nil : newVal
                    }
                )) {
                    Text("—").tag("")
                    ForEach(subTypeOptions, id: \.key) { opt in
                        Text(opt.name).tag(opt.key)
                    }
                }
                .disabled(typeKey == nil)
            }
        }
        .navigationTitle("Item-Daten")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Speichern") {
                    var meta = vm.meta(for: asset)
                    meta.notes = notesText
                    meta.types = typeKey
                    meta.subType = subTypeKey
                    vm.updateMeta(for: asset, meta)
                }
            }
        }
        .onAppear {
            let m = vm.meta(for: asset)
            notesText = m.notes
            typeKey = m.types
            subTypeKey = m.subType
        }
    }
}

#Preview {
    NavigationStack { EquipmentReservationCreateView() }
}
