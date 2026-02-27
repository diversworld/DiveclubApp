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
                ContentUnavailableView(
                    "Fehler",
                    systemImage: "exclamationmark.triangle",
                    description: Text(err)
                )

            } else if vm.reservations.isEmpty {
                ContentUnavailableView(
                    "Keine Reservierungen",
                    systemImage: "tray",
                    description: Text("Du hast aktuell keine Reservierungen.")
                )

            } else {
                List {
                    ForEach(vm.reservations) { r in
                        ReservationRow(reservation: r)
                    }
                }
            }
        }
        .navigationTitle("Reservierungen")
        .task { await vm.load() }
        .refreshable { await vm.load() }
    }
}

private struct ReservationRow: View {

    let reservation: ReservationDTO

    var body: some View {
        NavigationLink {
            EquipmentReservationDetailView(reservationId: reservation.id)
        } label: {
            VStack(alignment: .leading, spacing: 8) {

                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(reservation.title!)
                            .font(.headline)

                        Text("ID: #\(reservation.id)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    let s = statusLabel(reservation.reservationStatus)
                    Text(s.text)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(s.color.opacity(0.15))
                        .clipShape(Capsule())
                }

                if let reservedAt = reservation.reservedAt {
                    if let returnedAt = reservation.returnedAt {
                        Text("Reserviert am: \(formatDateTime(reservedAt)) – Zurückgegeben am:\(formatDateTime(returnedAt))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Reserviert am \(formatDateTime(reservedAt))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                if let fee = reservation.rentalFee {
                    Text("Gebühr: \(fee) €")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                // optional (falls Backend später items in Liste liefert)
                if let count = reservation.items?.count, count > 0 {
                    Text("\(count) Position(en)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 6)
        }
    }

    // MARK: - Helpers

    private func formatDateTime(_ unix: Int) -> String {
        let d = Date(timeIntervalSince1970: TimeInterval(unix))
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: d)
    }

    private func statusLabel(_ raw: String?) -> (text: String, color: Color) {
        let key = (raw ?? "").lowercased()
        switch key {
        case "pending", "open":
            return ("Offen", .orange)
        case "reserved":
            return ("Reserviert", .orange)
        case "confirmed", "approved":
            return ("Bestätigt", .blue)
        case "picked_up", "active":
            return ("Ausgegeben", .purple)
        case "returned", "closed":
            return ("Zurückgegeben", .green)
        case "cancelled", "canceled":
            return ("Storniert", .red)
        default:
            return ((raw ?? "Unbekannt").capitalized, .secondary)
        }
    }
}
