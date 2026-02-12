//
//  EquipmentCatalogView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 10.02.26.
//

import SwiftUI

struct EquipmentCatalogView: View {

    @StateObject private var vm = EquipmentCatalogViewModel()

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let err = vm.errorMessage {
                ContentUnavailableView("Fehler", systemImage: "exclamationmark.triangle", description: Text(err))
            } else {
                List {
                    if !vm.equipment.isEmpty {
                        Section("Ausrüstung") {
                            ForEach(vm.equipment) { a in
                                EquipmentAssetRow(asset: a)
                            }
                        }
                    }

                    if !vm.tanks.isEmpty {
                        Section("Flaschen") {
                            ForEach(vm.tanks) { a in
                                EquipmentAssetRow(asset: a)
                            }
                        }
                    }

                    if !vm.regulators.isEmpty {
                        Section("Regler") {
                            ForEach(vm.regulators) { a in
                                EquipmentAssetRow(asset: a)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Katalog")
        .task { await vm.load() }
        .refreshable { await vm.load() }
    }
}

private struct EquipmentAssetRow: View {
    let asset: EquipmentAsset

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(asset.title)
                .font(.headline)

            HStack(spacing: 10) {
                if let s = asset.status, !s.isEmpty {
                    Text("Status: \(s)")
                }
                if let fee = asset.fee, !fee.isEmpty {
                    Text("Gebühr: \(fee)")
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
