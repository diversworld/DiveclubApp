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
                // reset selection inputs
                selectedItemId = nil
                notes = ""
            }

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
                        .font(.footnote)
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
                                Text("Keine Artikel verfügbar").foregroundStyle(.secondary)
                            } else {
                                NavigationLink {
                                    ItemSelectionList(items: vm.availableItems, selectedId: $selectedItemId)
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
                                vm.addSelectedItem(selectedId: selectedItemId, notes: notes.isEmpty ? nil : notes)
                                // reset inputs
                                selectedItemId = nil
                                notes = ""
                            } label: {
                                Label("Zur Auswahl hinzufügen", systemImage: "plus.circle")
                            }
                            .disabled(selectedItemId == nil)
                        }

                        if !vm.selectedDrafts.isEmpty {
                            Section("Auswahl") {
                                ForEach(vm.selectedDrafts) { d in
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 4) {

                                            // ✅ schöner Titel
                                            Text(d.displayTitle.isEmpty ? "#\(d.itemId ?? 0)" : d.displayTitle)
                                                .font(.headline)

                                            // ✅ Subtitle (bei Reglern: Model 1st/2ndPri/2ndSec)
                                            if let sub = d.displaySubtitle, !sub.isEmpty {
                                                Text(sub)
                                                    .font(.footnote)
                                                    .foregroundStyle(.secondary)
                                            }

                                            // Equipment-spezifisch (optional weiterhin)
                                            if let t = d.types, !t.isEmpty {
                                                Text("Typ: \(t)")
                                                    .font(.footnote)
                                                    .foregroundStyle(.secondary)
                                            }
                                            if let st = d.subType, !st.isEmpty {
                                                Text("Subtyp: \(st)")
                                                    .font(.footnote)
                                                    .foregroundStyle(.secondary)
                                            }

                                            if let n = d.notes, !n.isEmpty {
                                                Text(n)
                                                    .font(.footnote)
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
                                HStack(spacing: 10) { ProgressView(); Text("Sende Reservierung …").foregroundStyle(.secondary) }
                            } else {
                                Button {
                                    Task { await vm.submitReservation(reservedFor: selectedMemberId) }
                                } label: { Label("Reservieren", systemImage: "tray.and.arrow.down") }
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
        }
        .alert("Erfolg", isPresented: $vm.submitSuccess) { Button("OK", role: .cancel) { vm.submitSuccess = false } } message: { Text("Reservierung gespeichert.") }
    }
}

private struct ItemSelectionList: View {
    let items: [Int: ReservationViewModel.ItemDisplay]
    @Binding var selectedId: Int?

    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        // Group by groupTitle when available (e.g., Equipment by Type)
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
            // If there is at least one non-empty header, render sections
            let hasGroups = groups.keys.contains { !$0.isEmpty }
            if hasGroups {
                ForEach(groups.keys.sorted(), id: \.self) { header in
                    Section(header: Text(header.isEmpty ? "" : header)) {
                        ForEach(groups[header]!.map { $0.0 }, id: \.self) { key in
                            let display = items[key]
                            Button {
                                selectedId = key
                                dismiss()        // ✅ zurück zur ReservationView
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(display?.title ?? "#\(key)")
                                            .foregroundColor(.primary)

                                        if let subtitle = display?.subtitle, !subtitle.isEmpty {
                                            Text(subtitle)
                                                .font(.footnote)
                                                .foregroundStyle(.secondary)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }

                                    Spacer()

                                    if selectedId == key {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                // Fallback: no grouping
                ForEach(Array(items.keys).sorted(), id: \.self) { key in
                    let display = items[key]
                    Button {
                        selectedId = key
                        dismiss()        // ✅ zurück zur ReservationView
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(display?.title ?? "#\(key)")
                                    .foregroundColor(.primary)

                                if let subtitle = display?.subtitle, !subtitle.isEmpty {
                                    Text(subtitle)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }

                            Spacer()

                            if selectedId == key {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack { ReservationView() }
}
