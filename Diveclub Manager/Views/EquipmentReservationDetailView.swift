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
                detailView(d) // ✅ ReservationDetailDTO
            } else {
                ContentUnavailableView("Keine Daten", systemImage: "tray", description: Text("Reservierung nicht gefunden."))
            }
        }
        .navigationTitle("Reservierung")
        .task { await vm.load() }
        .refreshable { await vm.load() }
    }

    private func detailView(_ d: ReservationDetailDTO) -> some View {
        List {
            Section("Status") {
                let s = statusLabel(d.reservationStatus)

                HStack {
                    Text((d.title?.isEmpty == false) ? d.title! : "Reservierung #\(d.id)")
                        .font(.headline)
                    Spacer()
                    Text(s.text)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(s.color.opacity(0.15))
                        .clipShape(Capsule())
                }

                /*if let raw = d.reservationStatus {
                    Text("raw: \(raw)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }*/
            }

            Section("Infos") {
                /*if let assetType = d.assetType, !assetType.isEmpty {
                    Text("Typ: \(assetType)")
                }*/
                if let reserved = d.reservedAt {
                    if let returned = d.returnedAt {
                        Text("Reserviert am: \(formatDateTime(reserved)) – Zuückgegeben am: \(formatDateTime(returned))")
                    } else {
                        Text("Reserviert am \(formatDateTime(reserved))")
                    }
                }
                if let fee = d.rentalFee, !fee.isEmpty {
                    Text("Gebühr: \(fee) €")
                }
                if let notes = d.notes, !notes.isEmpty {
                    Text(notes)
                }
            }

            Section("Items") {
                let items = d.items ?? []

                if !items.isEmpty {
                    // ✅ explizites id: verhindert Binding-ForEach
                    ForEach(items, id: \.id) { it in
                        VStack(alignment: .leading, spacing: 6) {

                            HStack {
                                Text(itemTypeLabel(it.itemType))
                                    .font(.headline)

                                Spacer()

                                let st = statusLabel(it.reservationStatus ?? d.reservationStatus)
                                Text(st.text)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(st.color.opacity(0.15))
                                    .clipShape(Capsule())
                            }

                            if let itemId = it.itemId, itemId != 0 {
                                Text("Item-ID: #\(itemId)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)

                                catalogDetailsView(itemType: it.itemType, itemId: itemId)
                            }

                            if let t = it.types, !t.isEmpty {
                                Text("Typ-Key: \(t)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            if let st = it.subType, !st.isEmpty {
                                Text("Subtyp-Key: \(st)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }

                            if let n = it.notes, !n.isEmpty {
                                Text(n)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }

                            // ✅ Regler-Modelle: Item → Reservation-Fallback
                            let m1  = (it.regModel1st?.isEmpty == false) ? it.regModel1st : d.regModel1st
                            let m2p = (it.regModel2ndPri?.isEmpty == false) ? it.regModel2ndPri : d.regModel2ndPri
                            let m2s = (it.regModel2ndSec?.isEmpty == false) ? it.regModel2ndSec : d.regModel2ndSec

                            if (m1?.isEmpty == false) || (m2p?.isEmpty == false) || (m2s?.isEmpty == false) {
                                if let v = m1, !v.isEmpty {
                                    Text("Modell 1. Stufe: \(v)")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                if let v = m2p, !v.isEmpty {
                                    Text("Modell 2. Stufe (prim): \(v)")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                if let v = m2s, !v.isEmpty {
                                    Text("Modell 2. Stufe (sec): \(v)")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                if let v = it.reservedAt { Text("Reserviert: \(formatDateTime(v))").font(.caption).foregroundStyle(.tertiary) }
                                if let v = it.pickedUpAt { Text("Abgeholt: \(formatDateTime(v))").font(.caption).foregroundStyle(.tertiary) }
                                if let v = it.returnedAt { Text("Zurück: \(formatDateTime(v))").font(.caption).foregroundStyle(.tertiary) }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } else {
                    ContentUnavailableView("Keine Items", systemImage: "tray", description: Text("Die Detail-API liefert keine Items."))
                }
            }
        }
    }

    // MARK: - Catalog Details (über VM Lookups)

    @ViewBuilder
    private func catalogDetailsView(itemType: String?, itemId: Int) -> some View {
        let raw = (itemType ?? "").lowercased()

        if raw.contains("tank") {
            if let t = vm.tanksById[itemId] {
                VStack(alignment: .leading, spacing: 4) {
                    let inv = (t.title?.isEmpty == false) ? t.title! : "Flasche #\(t.id)"
                    Text("Inventar: \(inv)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if let sub = t.displaySubtitle, !sub.isEmpty {
                        Text(sub).font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
        } else if raw.contains("regulator") {
            if let r = vm.regsById[itemId] {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Inventar: \(r.displayTitle)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if let sub = r.displaySubtitle, !sub.isEmpty {
                        Text(sub).font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
        } else if raw.contains("equipment") {
            if let e = vm.eqById[itemId] {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Inventar: \(e.displayTitle)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if let sub = e.displaySubtitle, !sub.isEmpty {
                        Text(sub).font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func itemTypeLabel(_ raw: String?) -> String {
        let s = (raw ?? "").lowercased()
        if s.contains("regulator") { return "Atemregler" }
        if s.contains("tank") { return "Flasche" }
        if s.contains("equipment") { return "Equipment" }
        return (raw?.isEmpty == false) ? raw! : "Item"
    }

    private func statusLabel(_ raw: String?) -> (text: String, color: Color) {
        let key = (raw ?? "").lowercased()
        switch key {
        case "pending", "open": return ("Offen", .orange)
        case "reserved": return ("Reserviert", .orange)
        case "confirmed", "approved": return ("Bestätigt", .blue)
        case "picked_up", "pickedup", "active": return ("Ausgegeben", .purple)
        case "returned", "closed": return ("Zurückgegeben", .green)
        case "cancelled", "canceled": return ("Storniert", .red)
        default:
            return (raw == nil ? "Unbekannt (nil)" : "Unbekannt (\(raw!))", .secondary)
        }
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
