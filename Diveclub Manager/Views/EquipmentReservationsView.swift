//
//  EquipmentReservationsView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 10.02.26.
//

import SwiftUI

struct EquipmentReservationsView: View {

    @StateObject private var vm = EquipmentReservationsViewModel()

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
                    ForEach(vm.reservations, id: \.id) { r in
                        ReservationRow(reservation: r)
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
                let s = statusLabel(r.reservationStatus)
                Text(s.text)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(s.color.opacity(0.15))
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
private struct ReservationRow: View {
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

    let reservation: EquipmentReservation

    var body: some View {
        NavigationLink(destination: EquipmentReservationDetailView(reservationId: reservation.id)) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Reservierung #\(reservation.id)")
                        .font(.headline)
                    Spacer()
                    let s = statusLabel(reservation.reservationStatus)
                    Text(s.text)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(s.color.opacity(0.15))
                        .clipShape(Capsule())
                }

                if let assetType = reservation.assetType, !assetType.isEmpty {
                    Text("Typ: \(assetType)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let reserved = reservation.reservedAt {
                    if let returned = reservation.returnedAt {
                        Text("\(formatDateTime(reserved)) – \(formatDateTime(returned))")
                             .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Reserviert am \(formatDateTime(reserved))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                if let count = reservation.items?.count, count > 0 {
                    Text("\(count) Position(en)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

