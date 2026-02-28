//
//  ReservationView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import SwiftUI

struct ReservationView: View {
    @StateObject private var vm = ReservationViewModel()

    @State private var selectedItemId: Int? = nil
    @State private var notes: String = ""
    @State private var selectedMemberId: Int? = nil

    let preselected: EquipmentAsset?

    init(preselected: EquipmentAsset? = nil) {
        self.preselected = preselected
    }

    // ✅ Hilfs-Flag: ist der aktuell gewählte Artikel schon in der Auswahl?
    private var alreadySelected: Bool {
        guard let id = selectedItemId else { return false }
        let type = vm.selectedCategory.assetType
        return vm.selectedDrafts.contains { $0.itemType == type && $0.itemId == id }
    }

    // ✅ IDs, die in dieser Kategorie bereits gewählt sind (für die Selection-Liste)
    private var takenIdsForCategory: Set<Int> {
        let type = vm.selectedCategory.assetType
        return Set(vm.selectedDrafts.compactMap { d in
            (d.itemType == type) ? d.itemId : nil
        })
    }

    var body: some View {
        VStack(spacing: 0) {

            // Category picker
            Picker("Kategorie", selection: $vm.selectedCategory) {
                ForEach(ReservationViewModel.Category.allCases) { cat in
                    Text(cat.displayName).tag(cat)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            .onChange(of: vm.selectedCategory) { _, newCat in
                Task { await vm.loadItems(for: newCat) }
                selectedItemId = nil
                notes = ""
            }

            // Member picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Reservieren für (optional)")

                Picker("Mitglied", selection: Binding(get: {
                    selectedMemberId
                }, set: { newVal in
                    selectedMemberId = newVal
                })) {
                    Text("Kein Mitglied").tag(Int?.none)
                    ForEach(vm.members) { m in
                        Text(m.fullName).tag(Int?.some(m.id))
                    }
                }
                .pickerStyle(.menu)

                if vm.members.isEmpty {
                    Text("Mitglieder konnten nicht geladen werden.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)

            Group {
                if vm.isLoading {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)

                } else if let err = vm.errorMessage {
                    ContentUnavailableView("Fehler", systemImage: "exclamationmark.triangle", description: Text(err))

                } else {
                    List {

                        Section("Artikel auswählen") {
                            if vm.availableItems.isEmpty {
                                Text("Keine Artikel verfügbar")
                                    .foregroundStyle(.secondary)
                            } else {
                                NavigationLink {
                                    ItemSelectionList(
                                        items: vm.availableItems,
                                        selectedId: $selectedItemId,
                                        takenIds: takenIdsForCategory
                                    )
                                    .navigationTitle("Artikel wählen")
                                } label: {
                                    HStack {
                                        Text("Artikel")
                                        Spacer()
                                        let display = selectedItemId.flatMap { vm.availableItems[$0] }
                                        Text(display?.title ?? "Bitte auswählen")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }

                            TextField("Notiz (optional)", text: $notes)

                            Button {
                                vm.addSelectedItem(
                                    selectedId: selectedItemId,
                                    notes: notes.isEmpty ? nil : notes
                                )
                                selectedItemId = nil
                                notes = ""
                            } label: {
                                Label("Zur Auswahl hinzufügen", systemImage: "plus.circle")
                            }
                            .disabled(selectedItemId == nil || alreadySelected)

                            if alreadySelected {
                                Text("Dieser Artikel ist bereits in der Auswahl.")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if !vm.selectedDrafts.isEmpty {
                            Section("Auswahl") {
                                ForEach(vm.selectedDrafts) { d in
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 4) {

                                            Text(d.displayTitle.isEmpty ? "#\(d.itemId ?? 0)" : d.displayTitle)
                                                .font(.headline)

                                            if let sub = d.displaySubtitle, !sub.isEmpty {
                                                Text(sub)
                                                    .font(.subheadline)
                                                    .foregroundStyle(.secondary)
                                            }

                                            if let t = d.types, !t.isEmpty {
                                                Text("Typ: \(t)")
                                                    .font(.body)
                                                    .foregroundStyle(.secondary)
                                            }
                                            if let st = d.subType, !st.isEmpty {
                                                Text("Subtyp: \(st)")
                                                    .font(.body)
                                                    .foregroundStyle(.secondary)
                                            }

                                            if let n = d.notes, !n.isEmpty {
                                                Text(n)
                                                    .font(.body)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }

                                        Spacer()

                                        Button(role: .destructive) {
                                            vm.selectedDrafts.removeAll { $0.id == d.id }
                                        } label: {
                                            Image(systemName: "trash")
                                        }
                                    }
                                }
                            }
                        }

                        Section {
                            if vm.isSubmitting {
                                HStack(spacing: 10) {
                                    ProgressView()
                                    Text("Sende Reservierung …")
                                        .foregroundStyle(.secondary)
                                }
                            } else {
                                Button {
                                    Task { await vm.submitReservation(reservedFor: selectedMemberId) }
                                } label: {
                                    Label("Reservieren", systemImage: "tray.and.arrow.down")
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(vm.selectedDrafts.isEmpty)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Reservierung")
        .task {
            await vm.loadMembers()
            await vm.loadItems(for: vm.selectedCategory)

            // Optional: preselected direkt setzen
            if let preselected, selectedItemId == nil {
                // nur übernehmen, wenn Kategorie passt
                switch preselected.type {
                case .tank: vm.selectedCategory = .tank
                case .regulator: vm.selectedCategory = .regulator
                case .equipment: vm.selectedCategory = .equipment
                }
                selectedItemId = preselected.id
            }
        }
        .alert("Erfolg", isPresented: $vm.submitSuccess) {
            Button("OK", role: .cancel) { vm.submitSuccess = false }
        } message: {
            Text("Reservierung gespeichert.")
        }
    }
}

private struct ItemSelectionList: View {
    let items: [Int: ReservationViewModel.ItemDisplay]
    @Binding var selectedId: Int?
    let takenIds: Set<Int>

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let groups: [String: [(Int, ReservationViewModel.ItemDisplay)]] = {
            var dict: [String: [(Int, ReservationViewModel.ItemDisplay)]] = [:]
            for key in items.keys.sorted() {
                if let display = items[key] {
                    let header = display.groupTitle ?? ""
                    dict[header, default: []].append((key, display))
                }
            }
            return dict
        }()

        return List {
            let hasGroups = groups.keys.contains { !$0.isEmpty }

            if hasGroups {
                ForEach(groups.keys.sorted(), id: \.self) { header in
                    Section(header: Text(header.isEmpty ? "" : header)) {
                        ForEach(groups[header]!.map { $0.0 }, id: \.self) { key in
                            let display = items[key]
                            let isTaken = takenIds.contains(key)

                            Button {
                                guard !isTaken else { return }
                                selectedId = key
                                dismiss() // ✅ zurück zur ReservationView
                            } label: {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(display?.title ?? "#\(key)")
                                            .foregroundStyle(.primary)

                                        if let subtitle = display?.subtitle, !subtitle.isEmpty {
                                            Text(subtitle)
                                                .font(.body)
                                                .foregroundStyle(.secondary)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }

                                    Spacer()

                                    if isTaken {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                    } else if selectedId == key {
                                        Image(systemName: "circle.inset.filled")
                                            .foregroundStyle(.blue)
                                    }
                                }
                                .opacity(isTaken ? 0.5 : 1.0)
                            }
                            .disabled(isTaken)
                        }
                    }
                }
            } else {
                ForEach(Array(items.keys).sorted(), id: \.self) { key in
                    let display = items[key]
                    let isTaken = takenIds.contains(key)

                    Button {
                        guard !isTaken else { return }
                        selectedId = key
                        dismiss()
                    } label: {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(display?.title ?? "#\(key)")
                                    .foregroundStyle(.primary)

                                if let subtitle = display?.subtitle, !subtitle.isEmpty {
                                    Text(subtitle)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }

                            Spacer()

                            if isTaken {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else if selectedId == key {
                                Image(systemName: "circle.inset.filled")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .opacity(isTaken ? 0.5 : 1.0)
                    }
                    .disabled(isTaken)
                }
            }
        }
    }
}

#Preview {
    NavigationStack { ReservationView() }
}
