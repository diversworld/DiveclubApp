//
//  EquipmentReservationCreateView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 10.02.26.
//

import SwiftUI

struct EquipmentReservationCreateView: View {

    @StateObject private var catalogVM = EquipmentCatalogViewModel()
    @StateObject private var vm = EquipmentReservationCreateViewModel()

    var body: some View {
        List {

            Section("Gegenstände auswählen") {
                if catalogVM.isLoading {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Lade Katalog …").foregroundStyle(.secondary)
                    }
                } else if let err = catalogVM.errorMessage {
                    Text(err).foregroundStyle(.red)
                } else {
                    selectionSection(title: "Ausrüstung", assets: catalogVM.equipment)
                    selectionSection(title: "Flaschen", assets: catalogVM.tanks)
                    selectionSection(title: "Regler", assets: catalogVM.regulators)
                }
            }

            Section {
                Button {
                    Task { await vm.submit() }
                } label: {
                    HStack {
                        Spacer()
                        if vm.isSubmitting {
                            ProgressView()
                        } else {
                            Text("Reservieren")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(vm.isSubmitting)
            }

            if let ok = vm.successMessage {
                Section {
                    Text(ok).foregroundStyle(.green)
                }
            }

            if let err = vm.errorMessage {
                Section {
                    Text(err).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Neue Reservierung")
        .task { await catalogVM.load() }
        .refreshable { await catalogVM.load() }
    }

    @ViewBuilder
    private func selectionSection(title: String, assets: [EquipmentAsset]) -> some View {
        if !assets.isEmpty {
            Section(title) {
                ForEach(assets) { a in
                    HStack(alignment: .center, spacing: 12) {

                        Button {
                            vm.toggle(asset: a)
                        } label: {
                            Image(systemName: vm.selected.contains("\(a.type.rawValue)#\(a.id)") ? "checkmark.circle.fill" : "circle")
                                .imageScale(.large)
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(a.title).font(.headline)

                            HStack(spacing: 10) {
                                if let s = a.status, !s.isEmpty {
                                    Text("Status: \(s)")
                                }
                                if let fee = a.fee, !fee.isEmpty {
                                    Text("Gebühr: \(fee)")
                                }
                            }
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Stepper(value: Binding(
                            get: { vm.quantity(for: a) },
                            set: { vm.setQuantity($0, for: a) }
                        ), in: 1...10) {
                            Text("\(vm.quantity(for: a))x")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .labelsHidden()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}
