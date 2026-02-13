//
//  EquipmentReservationDetailView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 10.02.26.
//

import SwiftUI

struct EquipmentReservationDetailView: View {

    @StateObject private var vm: EquipmentReservationDetailViewModel

    init(reservationId: Int) {
        _vm = StateObject(wrappedValue: EquipmentReservationDetailViewModel(reservationId: reservationId))
    }

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let err = vm.errorMessage {
                ContentUnavailableView("Fehler", systemImage: "exclamationmark.triangle", description: Text(err))
            } else if let d = vm.detail {
                detailView(d)
            } else {
                ContentUnavailableView("Keine Daten", systemImage: "tray", description: Text("Reservierung nicht gefunden."))
            }
        }
        .navigationTitle("Reservierung")
        .task { await vm.load() }
        .refreshable { await vm.load() }
    }

    private func detailView(_ d: EquipmentReservationDetail) -> some View {
        List {
            Section("Status") {
                Text((d.reservationStatus ?? "unknown").uppercased())
            }

            Section("Infos") {
                if let assetType = d.assetType, !assetType.isEmpty {
                    Text("Typ: \(assetType)")
                }

                if let fee = d.rentalFee, !fee.isEmpty {
                    Text("Gebühr: \(fee) €")
                }

                // ✅ Optional-String sauber behandeln
                if let notes = d.notes, !notes.isEmpty {
                    Text(notes)
                }
            }

            Section("Items") {
                if let items = d.items, !items.isEmpty {
                    ForEach(items) { it in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(it.itemType ?? "item") #\(it.itemId ?? 0)")
                            if let st = it.reservationStatus, !st.isEmpty {
                                Text(st).font(.footnote).foregroundStyle(.secondary)
                            }
                        }
                    }
                } else {
                    Text("Keine Items")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
