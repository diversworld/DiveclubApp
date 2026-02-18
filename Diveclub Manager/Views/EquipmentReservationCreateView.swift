import SwiftUI

struct EquipmentReservationCreateView: View {
    @StateObject private var vm = EquipmentRentalViewModel()

    var body: some View {
        Form {
            Section("Zeitraum") {
                DatePicker("Start", selection: $vm.startDate, displayedComponents: [.date, .hourAndMinute])
                DatePicker("Ende", selection: $vm.endDate, displayedComponents: [.date, .hourAndMinute])
            }

            Section("Optional: Für Mitglied-ID reservieren") {
                TextField("Mitglieds-ID (optional)", text: $vm.reservedFor)
                    .keyboardType(.numberPad)
            }

            Section("Zusatzfelder für Items") {
                TextField("Notes (optional)", text: $vm.defaultNotes)
                HStack {
                    Text("Sub-Type (optional)")
                    Spacer()
                    TextField("z. B. 3", value: $vm.defaultSubType, format: .number)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numberPad)
                }
                HStack(alignment: .firstTextBaseline) {
                    Text("Types (optional, kommasepariert)")
                    Spacer()
                    TextField("z. B. 1,2,3", text: Binding(
                        get: { vm.defaultTypes.map(String.init).joined(separator: ",") },
                        set: { input in
                            let parts = input.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
                            vm.defaultTypes = parts
                        }
                    ))
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numbersAndPunctuation)
                }
            }

            Section("Auswahl") {
                if vm.assets.isEmpty {
                    Text("Lade Katalog...")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(vm.assets) { asset in
                        HStack {
                            Button {
                                vm.toggleSelection(asset)
                            } label: {
                                HStack {
                                    Image(systemName: vm.isSelected(asset) ? "checkmark.circle.fill" : "circle")
                                    VStack(alignment: .leading) {
                                        Text(asset.title)
                                        if let fee = asset.fee, !fee.isEmpty {
                                            Text("Gebühr: \(fee)")
                                                .font(.footnote)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    if !vm.isAvailable(asset) {
                                        Text("nicht verfügbar")
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)

                            // Edit per-item meta
                            NavigationLink("Bearbeiten") {
                                PerItemMetaEditor(asset: asset, vm: vm)
                            }
                            .disabled(!vm.isSelected(asset))
                        }
                    }
                }
            }

            if let err = vm.errorMessage {
                Section {
                    Text(err)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Neue Reservierung")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Reservieren") { Task { await vm.createReservation() } }
                    .disabled(vm.selected.isEmpty)
            }
        }
        .task { await vm.loadAssets() }
        .refreshable { await vm.loadAssets() }
        .alert("Erfolg", isPresented: Binding(
            get: { vm.successMessage != nil },
            set: { _ in vm.successMessage = nil }
        )) {
            Button("OK") { }
        } message: {
            Text(vm.successMessage ?? "")
        }
    }
}
private struct PerItemMetaEditor: View {
    let asset: EquipmentAsset
    @ObservedObject var vm: EquipmentRentalViewModel

    @State private var typesText: String = ""
    @State private var subTypeValue: Int? = nil
    @State private var notesText: String = ""

    var body: some View {
        Form {
            Section(header: Text(asset.title)) {
                TextField("Notes", text: $notesText)
                HStack {
                    Text("Sub-Type")
                    Spacer()
                    TextField("z. B. 3", value: $subTypeValue, format: .number)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numberPad)
                }
                HStack(alignment: .firstTextBaseline) {
                    Text("Types (kommasepariert)")
                    Spacer()
                    TextField("z. B. 1,2,3", text: $typesText)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numbersAndPunctuation)
                }
            }
        }
        .navigationTitle("Item-Daten")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Speichern") {
                    let types = typesText.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
                    var meta = EquipmentRentalViewModel.ItemMeta()
                    meta.types = types
                    meta.subType = subTypeValue
                    meta.notes = notesText
                    vm.updateMeta(for: asset, meta)
                }
            }
        }
        .onAppear {
            let m = vm.meta(for: asset)
            typesText = m.types.map(String.init).joined(separator: ",")
            subTypeValue = m.subType
            notesText = m.notes
        }
    }
}

