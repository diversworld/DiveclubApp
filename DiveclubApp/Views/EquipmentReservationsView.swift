//
//  EquipmentReservationsView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 10.02.26.
//

import SwiftUI

struct EquipmentReservationsView: View {

    @StateObject private var vm = EquipmentReservationsViewModel()

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let err = vm.errorMessage {
                ContentUnavailableView("Fehler", systemImage: "exclamationmark.triangle", description: Text(err))
            } else if vm.reservations.isEmpty {
                ContentUnavailableView("Keine Reservierungen", systemImage: "tray", description: Text("Du hast aktuell keine Reservierungen."))
            } else {
                List {
                    ForEach(vm.reservations) { r in
                        NavigationLink {
                            EquipmentReservationDetailView(reservationId: r.id)
                        } label: {
                            reservationRow(r)
                        }
                    }
                }
            }
        }
        .navigationTitle("Reservierungen")
        .task { await vm.load() }
        .refreshable { await vm.load() }
    }

    private func reservationRow(_ r: EquipmentReservation) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Reservierung #\(r.id)")
                    .font(.headline)
                Spacer()
                Text((r.reservationStatus ?? "unknown").uppercased())
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.thinMaterial)
                    .clipShape(Capsule())
            }

            if let reserved = r.reservedAt {
                if let returned = r.returnedAt {
                    Text("\(formatDateTime(reserved)) – \(formatDateTime(returned))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Reserviert am \(formatDateTime(reserved))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            if let count = r.items?.count, count > 0 {
                Text("\(count) Position(en)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDateTime(_ unix: Int) -> String {
        let d = Date(timeIntervalSince1970: TimeInterval(unix))
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: d)
    }
}
