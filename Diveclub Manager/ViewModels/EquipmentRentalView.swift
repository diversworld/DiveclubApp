import SwiftUI

struct EquipmentRentalView: View {
    @StateObject private var vm = EquipmentRentalViewModel()

    @State private var selectedMemberId: Int? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {

                Picker("Kategorie", selection: $vm.selectedCategory) {
                    ForEach(EquipmentRentalViewModel.Category.allCases) { cat in
                        Text(cat.rawValue.capitalized).tag(cat)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: vm.selectedCategory) { _, _ in
                    Task { await vm.loadAssets() }
                }

                List(vm.visibleAssets, id: \.id) { asset in
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(asset.title)
                            if let details = asset.details, !details.isEmpty {
                                Text(details)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(3)
                            } else if let status = asset.status {
                                Text(status)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        let isSel = vm.isSelected(asset)
                        Button(isSel ? "Entfernen" : "Vormerken") {
                            vm.toggleSelection(asset)
                        }
                        .buttonStyle(.bordered)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Kommentar")
                    TextField("Optionaler Kommentar", text: $vm.defaultNotes)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)

                HStack {
                    Button("Weiter") {
                        vm.goToNextCategory()
                        Task { await vm.loadAssets() }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Reservieren") {
                        Task { await vm.createReservation() }
                    }
                    .buttonStyle(.bordered)
                    .disabled(vm.selected.isEmpty)
                }            }
            .navigationTitle("Reservierungen")
            .task {
                await vm.loadAssets()
            }
            .alert("Fehler", isPresented: Binding(get: { vm.errorMessage != nil }, set: { _ in vm.errorMessage = nil })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(vm.errorMessage ?? "Unbekannter Fehler")
            }
            .overlay(alignment: .top) {
                if let msg = vm.successMessage {
                    Text(msg)
                        .padding(8)
                        .background(.green.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding()
                }
            }
        }
    }
}

#Preview {
    EquipmentRentalView()
}
